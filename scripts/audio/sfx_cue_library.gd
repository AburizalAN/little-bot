class_name SfxCueLibrary
extends RefCounted
## Builds and caches LITTLE BOT's retro cyberpunk sound effect cues once at startup.

enum Cue {
	JUMP,
	ORB_PICKUP,
	CRASH,
	VICTORY,
	UI_CLICK,
}

var _cues: Dictionary = {}


func _init() -> void:
	_build_default_cues()


func get_stream(cue: Cue) -> AudioStreamWAV:
	if not _cues.has(cue):
		return null
	return _cues[cue] as AudioStreamWAV


func has_cue(cue: Cue) -> bool:
	return _cues.has(cue) and (_cues[cue] is AudioStreamWAV)


func _build_default_cues() -> void:
	_cues[Cue.JUMP] = RetroWaveSynthesizer.create_pitch_sweep(
		230.0,
		590.0,
		0.11,
		RetroWaveSynthesizer.Waveform.PULSE_25,
		0.34,
		0.65
	)

	var orb_freqs: Array[float] = [1046.5, 1568.0]
	var orb_durs: Array[float] = [0.055, 0.095]
	_cues[Cue.ORB_PICKUP] = RetroWaveSynthesizer.create_note_sequence(
		orb_freqs,
		orb_durs,
		RetroWaveSynthesizer.Waveform.SQUARE_50,
		0.32
	)

	_cues[Cue.CRASH] = RetroWaveSynthesizer.create_pitch_sweep(
		310.0,
		62.0,
		0.30,
		RetroWaveSynthesizer.Waveform.SAW,
		0.38,
		0.85,
		0.42
	)

	var win_freqs: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var win_durs: Array[float] = [0.09, 0.09, 0.09, 0.24]
	_cues[Cue.VICTORY] = RetroWaveSynthesizer.create_note_sequence(
		win_freqs,
		win_durs,
		RetroWaveSynthesizer.Waveform.PULSE_25,
		0.34
	)

	_cues[Cue.UI_CLICK] = RetroWaveSynthesizer.create_pitch_sweep(
		860.0,
		1280.0,
		0.048,
		RetroWaveSynthesizer.Waveform.TRIANGLE,
		0.28,
		0.80
	)
