extends VBoxContainer

@onready var average_label : Label = $StatusBar/AveragePerformanceLabel
@onready var top_performer_label : Label = $StatusBar/TopPerformanceLabel
@onready var employee_list : VBoxContainer = $HBoxContainer/EmployeeScroll/EmployeesList

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_GOOD := Color(0.3, 0.85, 0.45)
const COLOR_OK := Color(0.95, 0,75, 0.25)
const COLOR_BAD := Color(0.92, 0.35, 0.35)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)

func _ready() -> void:
	CompanyData.company_data_updated.connect(_refresh_all)
	visibility_changed.connect(func():
		if visible:
			_refresh_all()
	)
	_refresh_all()
	
func _refresh_all() -> void:
	if CompanyData.employees.is_empty():
		average_label.text = "Average Performance: -"
		top_performer_label.text = "Top Performer: -"
	else:
		var total := 0.0
		var top_employee : Dictionary = {}
		for e in CompanyData.employees:
			total += e["performance"]
			if top_employee.is_empty() or e["performance"] > top_employee["performance"]:
				top_employee = e
		
		average_label.text = "Average Performance: %.0f" % (total / CompanyData.employees.size())
		top_performer_label.text = "Top Performer: %s (%.0f)" % [top_employee["name"], top_employee["performance"]]
	
	for child in employee_list.get_children():
		child.queue_free()
	
	if CompanyData.employees.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No employees hired yet"
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		employee_list.add_child(empty_label)
		return
	
	var sorted_employees = CompanyData.employees.duplicate()
	sorted_employees.sort_custom(func(a, b): return a["performance"] > b["performance"])
	
	for employee in sorted_employees:
		_add_employee_card(employee)
	
func _performance_color(value: float) -> Color:
	if value >= 70:
		return COLOR_GOOD
	if value >= 40:
		return COLOR_OK
	return COLOR_BAD
	
func _add_employee_card(employee: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_BG
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	employee_list.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label := Label.new()
	name_label.text = "%s - %s" % [employee["name"], employee["role"]]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var value_label := Label.new()
	value_label.text = "%.0f" % employee["performance"]
	value_label.add_theme_color_override("font_color", _performance_color(employee["performance"]))
	value_label.add_theme_font_size_override("font_size", 16)
	header.add_child(value_label)
	
	var perf_bar := ProgressBar.new()
	perf_bar.min_value = 0
	perf_bar.max_value = 100
	perf_bar.value = employee["performance"]
	perf_bar.show_percentage = false
	perf_bar.custom_minimum_size = Vector2(0, 6)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = _performance_color(employee["performance"])
	fill_style.set_corner_radius_all(3)
	perf_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(perf_bar)
	
	var history : Array = employee.get("kpi_history", [])
	if history.size() >= 2:
		var sparkline := PerformanceSparkline.new()
		sparkline.custom_minimum_size = Vector2(0, 40)
		vbox.add_child(sparkline)
		sparkline.set_data(history, _performance_color(employee["performance"]))
		
		var trend = history[-1] - history[-2]
		var trend_label := Label.new()
		if trend > 0.5:
			trend_label.text = "↑ Improving (+%.1f this month)" % trend
			trend_label.add_theme_color_override("font_color", COLOR_GOOD)
		elif trend < -0.5:
			trend_label.text = "↓ Declining (%.1f this month)" % trend
			trend_label.add_theme_color_override("font_color", COLOR_BAD)
		else:
			trend_label.text = "→ Stable"
			trend_label.add_theme_color_override("font_color", COLOR_MUTED)
		trend_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(trend_label)
	else:
		var no_data_label := Label.new()
		no_data_label.text = "Not enough history yet"
		no_data_label.add_theme_color_override("font_color", COLOR_MUTED)
		no_data_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(no_data_label)
	
class PerformanceSparkline extends Control:
	var data : Array = []
	var line_color : Color = Color.WHITE
	
	func set_data(new_data: Array, color: Color) -> void:
		data = new_data
		line_color = color
		queue_redraw()
	
	func _draw() -> void:
		if data.size() < 2:
			return
		
		var max_value = data.max()
		var min_value = data.min()
		var range_val = max(max_value - min_value, 1.0)
		
		var points := PackedVector2Array()
		for i in data.size():
			var x = (float(i) / (data.size() - 1)) * size.x
			var normalized = (data[i] - min_value) / range_val
			var y = size.y - (normalized * size.y)
			points.append(Vector2(x, y))
		
		for i in points.size() - 1:
			draw_line(points[i], points[i + 1], line_color, 2.0)
		
		draw_circle(points[-1], 3.0, line_color)
	
