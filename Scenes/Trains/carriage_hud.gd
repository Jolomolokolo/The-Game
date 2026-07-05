extends Control

@export var box_size := Vector2(60, 35)
@export var box_spacing := 8.0
@export var box_color := Color(0.4, 0.7, 1.0)
@export var box_color_empty := Color(0.2, 0.2, 0.3)
@export var box_outline := Color(0.6, 0.8, 1.0)
@export var max_carriages := 10

var train_node : Node = null

func _ready() -> void:
	custom_minimum_size = Vector2(500, box_size.y + 35)
	size = Vector2(500, box_size.y + 35)
	
func initialize(train: Node):
	train_node = train
	
func _process(delta: float):
	queue_redraw()
	
func _draw() -> void:
	if not train_node:
		return
	
	var coupled = train_node.get("_coupled_carriages")
	var count = coupled.size() if coupled else 0
	
	var loco_offset_y = 12.0
	var loco_size = Vector2(box_size.x + 10, box_size.y)
	var total_carriages_width = count * (box_size.x + box_spacing)
	var loco_x = total_carriages_width + box_spacing
	
	for i in range(count):
		var x = i * (box_size.x + box_spacing)
		var rect = Rect2(Vector2(x, loco_offset_y), box_size)
		draw_rect(rect, box_color, true)
		draw_rect(rect, box_outline, false, 1.5)
		draw_string(ThemeDB.fallback_font,
			Vector2(x + box_size.x * 0.5 - 4, loco_offset_y + box_size.y * 0.5 + 4),
			str(count - i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		var cwy = loco_offset_y + box_size.y + 8
		draw_circle(Vector2(x + 10, cwy), 7.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + box_size.x - 10, cwy), 7.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(x + 10, cwy), 3.5, Color(0.3, 0.3, 0.3))
		draw_circle(Vector2(x + box_size.x - 10, cwy), 3.5, Color(0.3, 0.3, 0.3))
	
	draw_rect(Rect2(Vector2(loco_x, loco_offset_y), loco_size), Color(0.8, 0.2, 0.2), true)
	draw_rect(Rect2(Vector2(loco_x, loco_offset_y), loco_size), Color(1.0, 0.4, 0.4), false, 1.5)
	
	var cab_w = loco_size.x * 0.35
	var cab_h = loco_size.y * 0.7
	draw_rect(Rect2(Vector2(loco_x, loco_offset_y - cab_h * 0.3), Vector2(cab_w, cab_h)), Color(0.6, 0.15, 0.15), true)
	draw_rect(Rect2(Vector2(loco_x + loco_size.x - 16, loco_offset_y - 10), Vector2(8, 12)), Color(0.3, 0.3, 0.3), true)
	
	draw_string(ThemeDB.fallback_font,
		Vector2(loco_x + loco_size.x * 0.5 - 8, loco_offset_y + loco_size.y * 0.5 + 4),
		"LOK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	
	var wheel_y = loco_offset_y + loco_size.y + 8
	for wx in [loco_x + 10, loco_x + loco_size.x * 0.5, loco_x + loco_size.x - 10]:
		draw_circle(Vector2(wx, wheel_y), 8.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(wx, wheel_y), 4.0, Color(0.3, 0.3, 0.3))
	
