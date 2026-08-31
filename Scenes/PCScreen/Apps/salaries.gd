extends VBoxContainer

@onready var payroll_label : Label = $StatusBar/PayrollLabel
@onready var employees_list : VBoxContainer = $HBoxContainer/EmployeesScroll/EmployeesList

const COLOR_MUTED := Color(0.55, 0.6, 0.68)
const COLOR_NEGATIVE := Color(0.973, 0.443, 0.443, 1.0)
const COLOR_DAY_OFF := Color(0.65, 0.5, 0.95)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)

const SALARY_STEP := 50.0
const MONTH_NAMES := [
	"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
]

func _ready() -> void:
	CompanyData.company_data_updated.connect(_refresh_all)
	visibility_changed.connect(func():
		if visible:
			_refresh_all()
	)
	_refresh_all()
	
func _refresh_all() -> void:
	var total := 0.0
	for e in CompanyData.employees:
		total += e["salary_monthly"]
	payroll_label.text = "Total Monthly Payroll: %s" % NumberFormat.format(total)
	
	for child in employees_list.get_children():
		child.queue_free()
	
	if CompanyData.employees.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No employees hired yet"
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		employees_list.add_child(empty_label)
		return
	
	for employee in CompanyData.employees:
		_add_employee_row(employee)
	
func _add_employee_row(employee: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_BG
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	employees_list.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label := Label.new()
	name_label.text = "%s - %s" % [employee["name"], employee["role"]]
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var hired_label := Label.new()
	hired_label.text = "Hired: %s %d" % [MONTH_NAMES[employee["hired_month"]], employee["hired_year"]]
	hired_label.add_theme_color_override("font_color", COLOR_MUTED)
	hired_label.add_theme_font_size_override("font_size", 12)
	header.add_child(hired_label)
	
	var salary_row := HBoxContainer.new()
	salary_row.add_theme_constant_override("separation", 8)
	vbox.add_child(salary_row)
	
	var salary_label := Label.new()
	salary_label.text = "%s/mo" % NumberFormat.format(employee["salary_monthly"])
	salary_label.add_theme_color_override("font_color", COLOR_NEGATIVE)
	salary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salary_row.add_child(salary_label)
	
	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(32, 0)
	minus_button.pressed.connect(func():
		CompanyData.set_salary(employee["id"], employee["salary_monthly"] - SALARY_STEP)
		)
	salary_row.add_child(minus_button)
	
	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(32, 0)
	plus_button.pressed.connect(func():
		CompanyData.set_salary(employee["id"], employee["salary_monthly"] + SALARY_STEP)
		)
	salary_row.add_child(plus_button)
	
	var note_label := Label.new()
	note_label.text = "Underpaying employees may hurt performance over time"
	note_label.add_theme_color_override("font_color", COLOR_MUTED)
	note_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(note_label)
	
	var days_off_label := Label.new()
	var days_off_text = "No days off scheduled" if employee["days_off"].is_empty() else _format_days_off(employee["days_off"])
	days_off_label.text = "%s" % days_off_text
	days_off_label.add_theme_color_override("font_color", COLOR_DAY_OFF)
	days_off_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(days_off_label)
	
	var grant_row := HBoxContainer.new()
	grant_row.add_theme_constant_override("separation", 8)
	vbox.add_child(grant_row)
	
	var day_spin := SpinBox.new()
	day_spin.min_value = GameData.current_day
	day_spin.max_value = 30
	day_spin.value = GameData.current_day
	day_spin.size_flags_horizontal =Control.SIZE_EXPAND_FILL
	grant_row.add_child(day_spin)

	
	var grant_button := Button.new()
	grant_button.text = "Grant Day Off"
	grant_button.pressed.connect(func():
		CompanyData.request_day_off(employee["id"], GameData.current_month, GameData.current_year, int(day_spin.value))
		)
	grant_row.add_child(grant_button)
	
func _format_days_off(days_off: Array) -> String:
	var relevant := days_off.filter(func(d):
		return d["month"] == GameData.current_month and d["year"] == GameData.current_year
		)
	if relevant.is_empty():
		return "No days off this month"
	var day_numbers : Array[String] = []
	for d in relevant:
		day_numbers.append(str(d["day"]))
	return "Off this month on: " + ", ".join(day_numbers)
	
