class_name RetroWaveSynthesizer
extends RefCounted
## Pure procedural 16-bit PCM synthesizer generating lightweight AudioStreamWAV
## buffers in memory with zero external audio file dependencies.

const SAMPLE_RATE: int = 22050
const INT16_MAX: float = 32767.0
const ATTACK_SECONDS: float = 0.004

enum Waveform {
	PULSE_25,
	SQUARE_50,
	TRIANGLE,
	SAW,
}


static func create_pitch_sweep(
	start_hz: float,
	end_hz: float,
	duration_sec: float,
	waveform: Waveform,
	amplitude: float = 0.35,
	curve_exp: float = 1.0,
	noise_mix: float = 0.0
) -> AudioStreamWAV:
	var sample_count: int = maxi(1, roundi(duration_sec * float(SAMPLE_RATE)))
	var pcm_bytes: PackedByteArray = PackedByteArray()
	pcm_bytes.resize(sample_count * 2)

	var phase: float = 0.0
	var lfsr: int = 0x7FFF
	var clamped_noise: float = clampf(noise_mix, 0.0, 1.0)

	for i in range(sample_count):
		var t_sec: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(sample_count)
		var shaped_t: float = pow(progress, curve_exp)
		var freq: float = lerpf(start_hz, end_hz, shaped_t)

		phase = fmod(phase + (freq / float(SAMPLE_RATE)), 1.0)
		var tone: float = _sample_waveform(waveform, phase)

		if clamped_noise > 0.0:
			# Update 15-bit retro LFSR noise periodically for crunchy chiptune texture
			if (i % 6) == 0:
				var bit: int = ((lfsr >> 0) ^ (lfsr >> 1)) & 1
				lfsr = (lfsr >> 1) | (bit << 14)
			var noise_val: float = 1.0 if (lfsr & 1) == 1 else -1.0
			tone = lerpf(tone, noise_val, clamped_noise)

		var env: float = _compute_envelope(t_sec, duration_sec)
		var final_sample: float = clampf(tone * env * amplitude, -1.0, 1.0)
		pcm_bytes.encode_s16(i * 2, roundi(final_sample * INT16_MAX))

	return _build_wav_stream(pcm_bytes)


static func create_note_sequence(
	frequencies_hz: Array[float],
	durations_sec: Array[float],
	waveform: Waveform,
	amplitude: float = 0.34
) -> AudioStreamWAV:
	var note_count: int = mini(frequencies_hz.size(), durations_sec.size())
	var total_samples: int = 0
	for n in range(note_count):
		total_samples += maxi(1, roundi(durations_sec[n] * float(SAMPLE_RATE)))

	total_samples = maxi(1, total_samples)
	var pcm_bytes: PackedByteArray = PackedByteArray()
	pcm_bytes.resize(total_samples * 2)

	var write_index: int = 0
	var phase: float = 0.0

	for n in range(note_count):
		var freq: float = frequencies_hz[n]
		var dur: float = maxf(durations_sec[n], 0.005)
		var note_samples: int = maxi(1, roundi(dur * float(SAMPLE_RATE)))

		for i in range(note_samples):
			if write_index >= total_samples:
				break
			var t_sec: float = float(i) / float(SAMPLE_RATE)
			phase = fmod(phase + (freq / float(SAMPLE_RATE)), 1.0)

			var fundamental: float = _sample_waveform(waveform, phase)
			var harmonic: float = _sample_waveform(Waveform.TRIANGLE, fmod(phase * 2.0, 1.0)) * 0.25
			var env: float = _compute_envelope(t_sec, dur)
			var final_sample: float = clampf((fundamental * 0.8 + harmonic) * env * amplitude, -1.0, 1.0)

			pcm_bytes.encode_s16(write_index * 2, roundi(final_sample * INT16_MAX))
			write_index += 1

	return _build_wav_stream(pcm_bytes)


static func _sample_waveform(waveform: Waveform, phase: float) -> float:
	match waveform:
		Waveform.PULSE_25:
			return 1.0 if phase < 0.25 else -1.0
		Waveform.SQUARE_50:
			return 1.0 if phase < 0.50 else -1.0
		Waveform.TRIANGLE:
			return 1.0 - 4.0 * absf(phase - 0.5)
		Waveform.SAW:
			return (2.0 * phase) - 1.0
	return 0.0


static func _compute_envelope(time_sec: float, duration_sec: float) -> float:
	if duration_sec <= 0.0:
		return 0.0
	var attack: float = clampf(time_sec / ATTACK_SECONDS, 0.0, 1.0)
	var remaining_ratio: float = clampf(1.0 - (time_sec / duration_sec), 0.0, 1.0)
	var decay: float = pow(remaining_ratio, 0.75)
	return attack * decay


static func _build_wav_stream(pcm_bytes: PackedByteArray) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm_bytes
	return stream
