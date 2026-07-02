extends Control

var rail_network : Node = null
var train_node : Node = null

@export var map_size := Vector2(200, 200)
@export var padding := 10.0
@export var track_color := Color(0.8, 0.8, 0.8)
@export var switch_main_color := Color(0.2, 0.8, 0.2)
@export var switch_branch_color := Color(0.8, 0.2, 0.2)
@export var train_color := Color(1.0, 0.8, 0.0)
@export var track_width := 2.0
@export var background_color := Color(0.05, 0.05, 0.1, 0.85)

var _track_points : Dictionary = {}
var _world_bounds = AABB()
var _ready_to_draw := false

func _ready():
	custom_minimum_size = map_size
	size = map_size
	
func initialize(network: Node, train: Node):
	rail_network = network
	train_node = train
	_bake_track_points()
	_ready_to_draw = true
	queue_redraw()
	
func _process(delta: float):
	if _ready_to_draw:
		queue_redraw()
	
func _draw():
	if not _ready_to_draw:
		return
	draw_rect(Rect2(Vector2.ZERO, map_size), background_color, true)
	draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.4, 0.4, 0.5), false, 1.0)
	
	for track_name in _track_points:
		var points = _track_points[track_name]
		if points.size() < 2:
			continue
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], track_color, track_width)
	
	if rail_network and rail_network.has_method("get_switches"):
		for sw in rail_network.get_switches():
			var sw_pos = _world_to_map(sw.get_world_position())
			var col = switch_main_color if sw.current_direction == "main" else switch_branch_color
			draw_circle(sw_pos, 5.0, col)
			draw_string(
				ThemeDB.fallback_font,
				sw_pos + Vector2(7, 4),
				sw.name,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 8,
				Color.WHITE
			)
	
	if train_node and is_instance_valid(train_node):
		var train_pos = _world_to_map(train_node.global_position)
		_draw_train_arrow(train_pos, train_node.global_rotation.y)
	
func _draw_train_arrow(pos: Vector2, angle_y: float):
	var size = 7.0
	var dir = Vector2(sin(-angle_y), -cos(-angle_y))
	var perp = Vector2(-dir.y, dir.x)
	
	var p1 = pos + dir * size
	var p2 = pos - dir * (size * 0.5) + perp * (size * 0.6)
	var p3 = pos - dir * (size * 0.5) - perp * (size * 0.6)
	
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), train_color)
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), train_color.darkened(0.3), 1.0)
	
func _bake_track_points():
	if not rail_network:
		return
	
	# HIER WEITER MACHEN
	
	
	
func _world_to_map(world_pos: Vector3) -> Vector2:
	var draw_area = map_size - Vector2(padding, padding) * 2.0
	var bounds_size = Vector2(
		_world_bounds.size.x if _world_bounds.size.x > 0.1 else 1.0,
		_world_bounds.size.z if _world_bounds.size.z > 0.1 else 1.0
	)
	
	var normalized = Vector2(
		(world_pos.x - _world_bounds.position.x) / bounds_size.x,
		(world_pos.z - _world_bounds.position.z) / bounds_size.z
	)
	
	return Vector2(padding, padding) + normalized * draw_area
