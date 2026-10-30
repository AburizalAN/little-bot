@tool
class_name GroundSegment
extends StaticBody2D
## Configurable pixel-aligned neon ground or elevated platform segment.
## Origin (0, 0) is the top-left corner so level layout and gap widths are exact.

const TOP_EDGE_THICKNESS: float = 3.0
const SUB_STRIP_OFFSET_Y: float = 8.0
const SUB_STRIP_THICKNESS: float = 2.0

@export_range(16.0, 4096.0, 1.0) var segment_width: float = 320.0:
	set(value):
		segment_width = maxf(value, 16.0)
		if is_node_ready():
			_rebuild_geometry()

@export_range(8.0, 256.0, 1.0) var segment_height: float = 46.0:
	set(value):
		segment_height = maxf(value, 8.0)
		if is_node_ready():
			_rebuild_geometry()

@export var one_way: bool = false:
	set(value):
		one_way = value
		if is_node_ready():
			_rebuild_geometry()

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _surface_body: Polygon2D = $SurfaceBody
@onready var _neon_top_edge: Polygon2D = $NeonTopEdge
@onready var _sub_glow_strip: Polygon2D = $SubGlowStrip


func _ready() -> void:
	_rebuild_geometry()


func _rebuild_geometry() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(segment_width, segment_height)
	_collision_shape.shape = shape
	_collision_shape.position = Vector2(segment_width * 0.5, segment_height * 0.5)
	_collision_shape.one_way_collision = one_way

	_surface_body.polygon = _make_rect_polygon(0.0, segment_width, 0.0, segment_height)

	var edge_bottom: float = minf(TOP_EDGE_THICKNESS, segment_height)
	_neon_top_edge.polygon = _make_rect_polygon(0.0, segment_width, 0.0, edge_bottom)

	var show_sub_strip: bool = segment_height >= (SUB_STRIP_OFFSET_Y + SUB_STRIP_THICKNESS + 2.0)
	_sub_glow_strip.visible = show_sub_strip
	if show_sub_strip:
		_sub_glow_strip.polygon = _make_rect_polygon(
			0.0,
			segment_width,
			SUB_STRIP_OFFSET_Y,
			SUB_STRIP_OFFSET_Y + SUB_STRIP_THICKNESS
		)


static func _make_rect_polygon(
	left: float,
	right: float,
	top: float,
	bottom: float
) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
