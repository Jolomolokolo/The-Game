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

const ROLES := ["Engineer", "Logistics", "Dispatcher", "Mechanic", "Driver"]
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
	var role = ROLES[randi() % ROLES.size()]
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
	
func 
	
	
	
