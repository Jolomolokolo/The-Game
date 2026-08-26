extends VBoxContainer

@onready var employee_count_label : Label = $StatusBar/EmployeeCountLabel
@onready var payroll_label : Label = $StatusBar/PayrollLabel
@onready var candidates_list : VBoxContainer = $HBoxContainer/VBoxContainer/CandidatesScroll/CandidatesList
@onready var employees_list : VBoxContainer = $HBoxContainer/VBoxContainer2/EmployeesScroll/EmployeesList

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_POSITIVE := Color(0.29, 0.871, 0.502, 1.0)
const COLOR_NEGATIVE := Color(0.973, 0.443, 0.443, 1.0)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)
const COLOR_BUSY_BG := Color(0.13, 0.11, 0.08, 0.6)

const FIRST_NAMES := ["Alex", "Jordan", "Sam", "Casey", "Morgan", "Riley", "Taylor", "Jamie", "Tintje"]
const LAST_NAMES := ["Smith", "Johnson", "Williams", "Brown", "Garcia", "Miller", "Davis"]

var candidates : Array[Dictionary] = []
const CANDIDATE_COUNT := 4 # Maybe ändern in Zukunft -> Skill Tree oder so

func _ready() -> void:
	CompanyData.company_data_updated.connect(_refresh_all)
	CompanyData.assignment_changed.connect(_refresh_all)
	_generate_candidates()
	_refresh_all()
	
func _generate_candidates() -> void:
	candidates.clear()
	for i in CANDIDATE_COUNT:
		candidates.append(_generate_candidate())
	
func _generate_candidate() -> Dictionary:
	var role = CompanyData.ROLES[randi() % CompanyData.ROLES.size()]
	var performance = randf_range(30.0, 85.0)
	var base_salary = lerp(800.0, 3000.0, performance / 100.0)
	var salary = snappedf(base_salary * randf_range(0.9, 1.1), 50.0)
	
	return {
		"name": "%s %s" % [FIRST_NAMES[randi() % FIRST_NAMES.size()], LAST_NAMES[randi() % LAST_NAMES.size()]],
		"role": role,
		"performance": performance,
		"salary": salary
	}
	
func _refresh_all() -> void:
	employee_count_label.text = "Employees: %d / %d" % [CompanyData.employees.size(), CompanyData.max_employees]
	
	var total_payroll := 0.0
	for e in CompanyData.employees:
		total_payroll += e["salary_monthly"]
	payroll_label.text = "Monthly Payroll: %s" % NumberFormat.format(total_payroll)
	
	_rebuild_candidates_list()
	_rebuild_employees_list()
	
func _rebuild_candidates_list() -> void:
	for child in candidates_list.get_children():
		child.queue_free()
	
	if CompanyData.employees.size() >= CompanyData.max_employees:
		_add_empty_label(candidates_list, "Maximum number of employees reached")
		return
	
	for candidate in candidates:
		_add_candidate_card(candidate)
	
func _rebuild_employees_list() -> void:
	for child in employees_list.get_children():
		child.queue_free()
	
	if CompanyData.employees.is_empty():
		_add_empty_label(employees_list, "No employees hired yet")
		return
	
	for employee in CompanyData.employees:
		_add_employee_card(employee)
	
func _add_empty_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_MUTED)
	parent.add_child(label)
	
func _add_candidate_card(candidate: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ROW_BG
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	candidates_list.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label := Label.new()
	name_label.text = "%s - %s" % [candidate["name"], candidate["role"]]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var salary_label := Label.new()
	salary_label.text = "%s/mo" % NumberFormat.format(candidate["salary"])
	salary_label.add_theme_color_override("font_color", COLOR_NEGATIVE)
	header.add_child(salary_label)
	
	var perf_row := HBoxContainer.new()
	perf_row.add_theme_constant_override("separation", 8)
	vbox.add_child(perf_row)
	
	var perf_bar := ProgressBar.new()
	perf_bar.min_value = 0
	perf_bar.max_value = 100
	perf_bar.value = candidate["performance"]
	perf_bar.show_percentage = false
	perf_bar.custom_minimum_size = Vector2(0, 6)
	perf_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perf_row.add_child(perf_bar)
	
	var perf_label := Label.new()
	perf_label.text = "%.0f" % candidate["performance"]
	perf_label.add_theme_color_override("font_color", COLOR_MUTED)
	perf_row.add_child(perf_label)
	
	var hire_button := Button.new()
	hire_button.text = "Hire"
	hire_button.pressed.connect(func():
		CompanyData.hire_employee(candidate["name"], candidate["role"], candidate["salary"], candidate["performance"])
		candidates.erase(candidate)
		candidates.append(_generate_candidate())
		_refresh_all()
	)
	vbox.add_child(hire_button)
	
func _add_employee_card(employee: Dictionary) -> void:
	var is_busy = employee["assigned_job_id"] != ""
	
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BUSY_BG if is_busy else COLOR_ROW_BG
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	employees_list.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label := Label.new()
	name_label.text = "%s - %s" % [employee["name"], employee["role"]]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var salary_label := Label.new()
	salary_label.text = "%s/mo" % NumberFormat.format(employee["salary_monthly"])
	salary_label.add_theme_color_override("font_color", COLOR_NEGATIVE)
	header.add_child(salary_label)
	
	var perf_row := HBoxContainer.new()
	perf_row.add_theme_constant_override("separation", 8)
	vbox.add_child(perf_row)
	
	var perf_bar := ProgressBar.new()
	perf_bar.min_value = 0
	perf_bar.max_value = 100
	perf_bar.value = employee["performance"]
	perf_bar.show_percentage = false
	perf_bar.custom_minimum_size = Vector2(0, 6)
	perf_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perf_row.add_child(perf_bar)
	
	var perf_label := Label.new()
	perf_label.text = "%.0f" % employee["performance"]
	perf_label.add_theme_color_override("font_color", COLOR_MUTED)
	perf_row.add_child(perf_label)
	
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	vbox.add_child(status_row)
	
	var status_label := Label.new()
	status_label.text = "On assignment" if is_busy else "Available"
	status_label.add_theme_color_override("font_color", COLOR_MUTED if is_busy else COLOR_POSITIVE)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status_label)
	
	var fire_button := Button.new()
	fire_button.text = "Fire"
	fire_button.pressed.connect(func():
		CompanyData.fire_employee(employee["id"])
	)
	status_row.add_child(fire_button)
	
