extends Control

@export var box_size := Vector2(60, 35)
@export var box_spacing := 8.0
@export var padding := 16.0

var train_node : Node = null
var _hovered_index : int = -1

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	
func initialize(train: Node) -> void:
	train_node = train
	
func show_menu():
	if not train_node:
		return
	_rebuild()
	visible = true
	
func hide_menu():
	visible = false
	
func _rebuild():
	var all_cariages = _get_all_carriages()
	var total_w = all_cariages.size() * (box_size.x + box_spacing) + padding * 2
	var total_h = box_size.y + 80.0
	custom_minimum_size = Vector2(total_w, total_h)
	size = Vector2(total_w, total_h)
	queue_redraw()
	
func _get_all_carriages():
	return train_node.get_tree().get_nodes_in_group("train_carriage")
	
func _process(_delta: float):
	if visible:
		_rebuild()
	
func _draw():
	if not train_node:
		return
	
	var coupled : Array = train_node.get("_coupled_carriages") if train_node.get("_coupled_carriages") else []
	var nearby = train_node.get("_nearby_carriage")
	var all_carriages = _get_all_carriages()
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.1, 0.9), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.4, 0.4), false, 1.5)#
	
	draw_string(ThemeDB.fallback_font,
		Vector2(padding, 20),
		"WAGEN MANAGEMENT  [C schließen]",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	
	for i in range(all_carriages.size()):
		var carriage = all_carriages[i]
		var x = padding + i * (box_size.x + box_spacing)
		var y = 32.0
		var rect = Rect2(Vector2(x, y), box_size)
		
		var is_coupled = coupled.has(carriage)
		var is_nearby = carriage == nearby
		var is_hovered = i == _hovered_index
		
		var col : Color
		
		if is_coupled:
			col = Color(0.2, 0.7, 0.3)
		if is_nearby:
			col = Color(0.8, 0.6, 0.1)
		if is_hovered:
			col = Color(0.3, 0.3, 0.4)
		
		if is_hovered:
			col = col.lightened(0.2)
		
		draw_rect(rect, col, true)
		draw_rect(rect, col.lightened(0.3), false, 1.5)
		
		var wy = y + box_size .y + 7
		draw_circle(Vector2(x + 10, wy), 6.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + box_size.x - 10, wy), 6.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + 10, wy), 3.0, Color(0.3, 0.3, 0.3))
		draw_circle(Vector2(x + box_size.x - 10, wy), 3.0, Color(0.3, 0.3, 0.3))
		
		var short_name = carriage.name.substr(carriage.name.length() - 4)
		draw_string(ThemeDB.fallback_font,
		Vector2(x + 4, y + box_size.y * 0.5 + 4),
		short_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		
		var status = "ON" if is_coupled else ("NEAR" if is_nearby else "FAR")
		draw_string(ThemeDB.fallback_font,
			Vector2(x + 2, y + box_size.y + 22),
			status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color.WHITE if is_coupled else (Color.YELLOW if is_nearby else Color.GRAY))
	
func _gui_input(event: InputEvent):
	if not train_node:
		return
	
	var coupled : Array = train_node.get("_coupled_carriages") if train_node.get("_coupled_carriages") else []
	var nearby = train_node.get("_nearby_carriage")
	var all_carriages = _get_all_carriages()
	
	if event is InputEventMouseMotion:
		_hovered_index = _get_carriage_at(event.position, all_carriages.size())
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx = _get_carriage_at(event.position, all_carriages.size())
		if idx < 0 or idx >= all_carriages.size():
			return
		
		var carriage = all_carriages[idx]
		
		if coupled.has(carriage):
			_decouple_specific(carriage)
		elif carriage == nearby:
			train_node.call("_couple_carriage", carriage)
		
		queue_redraw()
	
func _get_carriage_at(mouse_pos: Vector2, count: int) -> int:
	for i in range(count):
		var x = padding + i * (box_size.x + box_spacing)
		var rect = Rect2(Vector2(x, 32.0), box_size)
		if rect.has_point(mouse_pos):
			return i
	return -1
	
func _decouple_specific(carriage: Node):
	var coupled : Array = train_node.get("_coupled_carriages")
	if not coupled.has(carriage):
		return
	
	var idx = coupled.find(carriage)
	var to_decouple = coupled.slice(idx)
	for c in to_decouple:
		if is_instance_valid(c):
			c.call("decouple")
	coupled.resize(idx)
	print("[CoupleMenu] Abgekoppelt ab Index %d" % idx)
	
