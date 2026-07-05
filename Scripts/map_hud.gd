extends Control

var rail_network : Node = null
var train_node : Node = null

@export var map_size := Vector2(250, 250)
@export var padding := 10.0
@export var track_color := Color(0.8, 0.8, 0.8)
@export var switch_main_color := Color(0.2, 0.8, 0.2)
@export var switch_branch_color := Color(0.8, 0.2, 0.2)
@export var train_color := Color(1.0, 0.8, 0.0)
@export var track_width := 2.0
@export var background_color := Color(0.05, 0.05, 0.1, 0.85)

var _track_points : Dictionary = {}
var _world_min := Vector3.ZERO
var _world_max := Vector3.ZERO
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
	
func _process(_delta: float):
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
		var train_speed = train_node.get("speed") if train_node.get("speed") != null else 0.0
		var train_angle = train_node.global_rotation.y
		if train_speed < 0:
			train_angle += PI
		_draw_train_arrow(train_pos, train_angle)
		
	var carriages = train_node.get("_coupled_carriages")
	if carriages:
		for carriage in carriages:
			if is_instance_valid(carriage) and carriage.current_track != null and carriage.current_path_follow != null:
				var track = carriage.current_track
				var progress = carriage.current_progress
				var local_pos = track.curve.sample_baked(progress)
				var world_pos = track.to_global(local_pos)
				var map_pos = _world_to_map(world_pos)
				_draw_carriage_rect(map_pos, carriage.global_rotation.y)
	
func _draw_train_arrow(pos: Vector2, angle_y: float):
	var arrow_size = 5.0
	var dir = Vector2(sin(-angle_y), -cos(-angle_y))
	var perp = Vector2(-dir.y, dir.x)
	
	var p1 = pos + dir * arrow_size
	var p2 = pos - dir * (arrow_size * 0.5) + perp * (arrow_size * 0.8)
	var p3 = pos - dir * (arrow_size * 0.5) - perp * (arrow_size * 0.8)
	
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), train_color)
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), train_color.darkened(0.3), 1.0)
	
func _draw_carriage_rect(pos: Vector2, angle_y: float):
	var w := 3.0
	var h := 6.0
	var dir = Vector2(sin(-angle_y), -cos(-angle_y))
	var perp = Vector2(-dir.y, dir.x)
	
	var p1 = pos + dir * h * 0.5 + perp * w * 0.5
	var p2 = pos + dir * h * 0.5 - perp * w * 0.5
	var p3 = pos - dir * h * 0.5 - perp * w * 0.5
	var p4 = pos - dir * h * 0.5 + perp * w * 0.5
	
	var carriage_color = Color(0.4, 0.7, 1.0)
	draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), carriage_color)
	draw_polyline(PackedVector2Array([p1, p2, p3, p4]), carriage_color.darkened(0.3), 1.0)
	
func _bake_track_points():
	if not rail_network:
		return
	
	_track_points.clear()
	var all_world_points : Array[Vector3] = []
	
	for child in rail_network.get_children():
		if not child is Path3D:
			continue
		var path : Path3D = child
		if not path.curve:
			continue
	
		var length = path.curve.get_baked_length()
		var steps = clampi(int(length / 2.0) + 2, 2, 200)
	
		var points_3d : Array[Vector3] = []
		for i in range(steps):
			var t = float(i) / float(steps - 1)
			var local_pos = path.curve.sample_baked(t * length)
			var world_pos = path.to_global(local_pos)
			points_3d.append(world_pos)
			all_world_points.append(world_pos)
		
		_track_points[path.name] = points_3d
	
	if all_world_points.is_empty():
		return
	
	_world_min = all_world_points[0]
	_world_max = all_world_points[0]
	for p in all_world_points:
		_world_min.x = minf(_world_min.x, p.x)
		_world_min.z = minf(_world_min.z, p.z)
		_world_max.x = maxf(_world_max.x, p.x)
		_world_max.z = maxf(_world_max.z, p.z)
	
	for track_name in _track_points:
		var pts_2d : Array[Vector2] = []
		for p3 in _track_points[track_name]:
			pts_2d.append(_world_to_map(p3))
		_track_points[track_name] = pts_2d
	
func _world_to_map(world_pos: Vector3) -> Vector2:
	var draw_area = map_size - Vector2(padding, padding) * 2.0
	
	var bounds_x = (_world_max.x - _world_min.x) if (_world_max.x - _world_min.x) > 0.1 else 1.0
	var bounds_z = (_world_max.z - _world_min.z) if (_world_max.z - _world_min.z) > 0.1 else 1.0
	
	var normalized = Vector2(
		(world_pos.x - _world_min.x) / bounds_x,
		(world_pos.z - _world_min.z) / bounds_z
	)
	
	return Vector2(padding, padding) + normalized * draw_area
	
