extends Control

var net_worth_data : Array[float] = []
var cash_data : Array[float] = []
var debt_data : Array[float] = []

const GRID_COLOR := Color(1, 1, 1, 0.08)
const NET_WORTH_COLOR := Color(0.96, 0.78, 0.26)
const CASH_COLOR := Color(0.3, 0.85, 0.45)
const DEBT_COLOR := Color(0.92, 0.35, 0.35)

func set_data(net_worth: Array[float], cash: Array[float], debt: Array[float]) -> void:
	net_worth_data = net_worth
	cash_data = cash
	debt_data = debt
	queue_redraw()
	
func _draw() -> void:
	if net_worth_data.is_empty():
		return
	
	var max_val = net_worth_data.max()
	if debt_data.size() > 0:
		max_val = max(max_val, debt_data.max())
	if max_val <= 0:
		max_val = 1.0
	
	_draw_grid(max_val)
	_draw_filled_line(net_worth_data, max_val, NET_WORTH_COLOR, true)
	_draw_filled_line(cash_data, max_val, CASH_COLOR, false)
	_draw_filled_line(debt_data, max_val, DEBT_COLOR, false)
	
func _draw_grid(max_val: float) -> void:
	var steps := 5
	for i in range(steps + 1):
		var y = size.y - (float(i) / steps) * size.y
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, 1.0)
		var label_value = (float(i) / steps) * max_val
		draw_string(ThemeDB.fallback_font, Vector2(4, y - 4), "%.0f €" % label_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.6, 0.68))
		
func _points_from_data(data: Array[float], max_val: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if data.size() < 2:
		return points
	for i in data.size():
		var x = (float(i) / (data.size() - 1)) * size.x
		var y = size.y - (data[i] / max_val) * size.y
		points.append(Vector2(x, y))
	return points
	
func _draw_filled_line(data: Array[float], max_val: float, color: Color, fill: bool) -> void:
	var points = _points_from_data(data, max_val)
	if points.size() < 2:
		return
	
	if fill:
		var polygon = points.duplicate()
		polygon.append(Vector2(size.x, size.y))
		polygon.append(Vector2(0, size.y))
		draw_colored_polygon(polygon, Color(color.r, color.g, color.b, 0.18))
		
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], color, 2.0)
	
	
