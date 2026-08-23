extends Node

signal employee_hired(employee: Dictionary)
signal employee_fired(employee: Dictionary)
signal job_created(job: Dictionary)
signal job_completed(job: Dictionary)
signal job_failed(job: Dictionary)
signal assignment_changed
signal company_data_updated

var employees : Array[Dictionary] = []
var jobs: Array[Dictionary] = []

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
		unassign_job(employee["assigned_job_id"])
	
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
	
	
	
# EVTL.: HIER AUFTRAGE ERSTELLUNG
	
	
	
func assign_employee_to_job(employee_id: String, job_id: String) -> bool:
	var employee = get_employee(employee_id)
	var job = get_job(job_id)
	if employee.is_empty() or job.is_empty():
		return false
	if employee["assigned_job_id"] != "" or job["assigned_employee_id"] != "":
		return false
	
	employee["assigned_job_id"] = job_id
	job["assigned_employee_id"] = employee_id
	job["status"] = "in_progress"
	assignment_changed.emit()
	company_data_updated.emit()
	return true
	
func unassign_job(job_id: String) -> void:
	var job = get_job(job_id)
	if job.is_empty():
		return
	if job["assigned_employee_id"] != "":
		var employee = get_employee(job["assigned_employee_id"])
		if not employee.is_empty():
			employee["assigned_job_id"] = ""
	job["assigned_employee_id"] = ""
	job["status"] = "open"
	job["progress"] = 0.0
	assignment_changed.emit()
	company_data_updated.emit()
	
func get_job(job_id: String) -> Dictionary:
	for j in jobs:
		if j["id"] == job_id:
			return j
	return {}
	
func get_jobs_by_status(status: String) -> Array:
	return jobs.filter(func(j): return j["status"] == status)
	
func process_month(month: int, year: int) -> void:
	_pay_salaries()
	_progress_jobs(month, year)
	_update_kpis()
	
func _pay_salaries() -> void:
	var total := 0.0
	for e in employees:
		total += e["salary_monthly"]
	if total > 0:
		GameData.add_cash(-int(total), "Employee Salaries")
	
func _progress_jobs(month: int, year: int) -> void:
	var to_complete : Array[Dictionary] = []
	var to_fail : Array[Dictionary] = []
	
	for job  in jobs:
		if job["status"] != "in_progress":
			continue
		var employee = get_employee(job["assigned_job_id"])
		if employee.is_empty():
			continue
		
		var effectiveness= clampf(employee["performance"] / max(job["required_performance"], 1.0), 0.2, 2.0)
		job["progress"] = clampf(job["progress"] + 0.25 * effectiveness, 0.0, 1.0)
		
		var deadline_passed = (year > job["deadline_year"] or year == job["deadline_year"] and month > job["deadline_month"])
		
		if job["progress"] >= 1.0:
			to_complete.append(job)
		elif deadline_passed:
			to_fail.append(job)
			
	for job in to_complete:
		job["status"] = "completed"
		GameData.add_cash(int(job["reward"]), "Job Completed %s" % job["title"])
		
	
