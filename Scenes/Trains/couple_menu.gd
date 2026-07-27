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
	
	print("Nearby: ", train_node.call("get_nearby_carriages"))
	print("Coupled: ", train_node.call("get_coupled_carriages"))
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func hide_menu():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
	
	var nearby_list : Array = train_node.call("get_nearby_carriages")
	var coupled : Array = train_node.call("get_coupled_carriages")
	var all_carriages = _get_all_carriages()
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.1, 0.9), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.4, 0.4), false, 1.5)
	
	draw_string(ThemeDB.fallback_font,
		Vector2(padding, 20),
		"CARRIAGE MANAGMENT  [C close]",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	
	for i in range(all_carriages.size()):
		var carriage = all_carriages[i]
		var x = padding + i * (box_size.x + box_spacing)
		var y = 32.0
		var rect = Rect2(Vector2(x, y), box_size)
		
		var is_coupled = coupled.has(carriage)
		var is_nearby = nearby_list.has(carriage)
		var is_hovered = i == _hovered_index
		
		var col : Color
		if is_coupled:
			col = Color(0.2, 0.7, 0.3)
		elif is_nearby:
			col = Color(0.8, 0.6, 0.1)
		#elif is_hovered:
		else:
			col = Color(0.3, 0.3, 0.4)
		
		if is_hovered and (is_coupled or is_nearby):
			col = col.lightened(0.2)
		
		draw_rect(rect, col, true)
		draw_rect(rect, col.lightened(0.3), false, 1.5)
		
		var wy = y + box_size .y + 7
		draw_circle(Vector2(x + 10, wy), 6.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + box_size.x - 10, wy), 6.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + 10, wy), 3.0, Color(0.3, 0.3, 0.3))
		draw_circle(Vector2(x + box_size.x - 10, wy), 3.0, Color(0.3, 0.3, 0.3))
		
		var short_name = carriage.name.substr(max(carriage.name.length() - 6, 0))
		draw_string(ThemeDB.fallback_font,
		Vector2(x + 4, y + box_size.y * 0.5 + 4),
		short_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		
		var status = "ON" if is_coupled else ("NEAR" if is_nearby else "FAR")
		var status_col = Color.GREEN if is_coupled else (Color.YELLOW if is_nearby else Color.DARK_GRAY)
		draw_string(ThemeDB.fallback_font,
			Vector2(x + 2, y + box_size.y + 22),
			status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, status_col)
	
func _gui_input(event: InputEvent):
	if not train_node:
		return
	
	var nearby_list : Array = train_node.call("get_nearby_carriages")
	var coupled : Array = train_node.call("get_coupled_carriages")
	var all_carriages = _get_all_carriages()
	
	if event is InputEventMouseMotion:
		_hovered_index = _get_carriage_at(event.position, all_carriages.size())
		queue_redraw()
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx = _get_carriage_at(event.position, all_carriages.size())
		if idx < 0 or idx >= all_carriages.size():
			return
	
		var carriage = all_carriages[idx]
	
		if coupled.has(carriage):
			_decouple_specific(carriage)
		elif nearby_list.has(carriage):
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
	var coupled = train_node.get("_coupled_carriages")
	if not coupled.has(carriage):
		return
	
	var idx = coupled.find(carriage)
	while coupled.size() > idx:
		var last = coupled.back()
		coupled.pop_back()
		if is_instance_valid(last):
			last.call("decouple")
	print("CoupleMenu: Decoupled at Index %d" % idx)
	
