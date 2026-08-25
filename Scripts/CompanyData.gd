extends Node

signal employee_hired(employee: Dictionary)
signal employee_fired(employee: Dictionary)
signal company_data_updated
signal assignment_changed

var employees : Array[Dictionary] = []

var max_employees := 12 # LATER UPGRADEBEL and start only with 2 or even 0 employees

func hire_employee(name: String, role: String, salary: float, base_performance : float = 50.0) -> Dictionary:
	var employee := {
		"id": "emp_%d" % Time.get_ticks_usec(),
		"name": name,
		"role": role,
		"salary_monthly": salary,
		"hired_month": GameData.current_month,
		"hired_year": GameData.current_year,
		"performance": base_performance,
		"kpi_history": [] as Array[float],
		"days_off": [] as Array[Dictionary],
		"assigned_job_id": "",
		"status": "active"
	}
	employees.append(employee)
	employee_hired.emit(employee)
	company_data_updated.emit()
	return employee
	
func fire_employee(employee_id: String) -> void:
	var employee = get_employee(employee_id)
	if employee == null:
		return
	if employee["assigned_job_id"] != "":
		JobManager.release_job_for_employee(employee_id)
	employees.erase(employee)
	employee_fired.emit(employee)
	company_data_updated.emit()
	
func get_employee(employee_id: String) -> Dictionary:
	for e in employees:
		if e["id"] == employee_id:
			return e
	return {}
	
func get_available_employees() -> Array:
	return employees.filter(func(e): return e["status"] == "active" and e["assigned_job_id"] == "")
	
func request_day_off(employee_id: String, month: int, year: int, day: int) -> void:
	var employee = get_employee(employee_id)
	if employee.is_empty():
		return
	employee["days_off"].append({"month": month, "year": year, "day": day})
	company_data_updated.emit()
	
func is_employee_off(employee_id: String, month: int, year: int, day: int) -> bool:
	var employee = get_employee(employee_id)
	if employee.is_empty():
		return false
	for off in employee["days_off"]:
		if off["month"] == month and off["year"] == year and off["day"] == day:
			return true
	return false
	
func process_month(_month: int, _year: int) -> void:
	_pay_salaries()
	_update_kpis()
	
func _pay_salaries() -> void:
	var total := 0.0
	for e in employees:
		total += e["salary_monthly"]
	if total > 0:
		GameData.add_cash(-int(total), "Employee Salaries")
	
func _update_kpis() -> void:
	for e in employees:
		e["performance"] = clampf(e["performance"] + randf_range(-2.0, 3.0), 0, 100)
		e["kpi_history"].append(e["performance"])
