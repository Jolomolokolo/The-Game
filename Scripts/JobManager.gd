extends Node

signal job_completed(job)
signal job_accepted(job)
signal job_failed(job) # Adden -> also wenn Deadline abgelaufen ist
signal jobs_updated
signal rental_income_paid(amount: float)
signal rental_penalty_paid(amount: float)

enum JobStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED}

var availab_jobs : Array[Dictionary] = []
var active_jobs : Array[Dictionary] = []
var completed_jobs : Array[Dictionary] = []
var rented_trains :  Array[Dictionary] = []

var reputation : int = 0

const DAYS_PER_MONTH := 15
const EMERGENCY_CHANCE_PER_DAY := 0.08 # LATER PER SKILL TREE CHANGEN
const RENTAL_RETURN_GRACE_DAYS := 7
const EARLY_BONUS_REP_PER_DAY := 2
const EARLY_BOMUS_REP_CAP := 30

var fixed_job_templates : Array[Dictionary] = [
	{
		"id": "job_fixed_001",
		"title": "Express train to Depot B",
		"description": "Transport the train from Depot A to the Depot B.",
		"from_depot": "depot_a",
		"to_depot": "depot_b",
		"reward_money": 500.0,
		"reward_rep": 10,
		"time_limit_days": 0,
		"is_fixed": true,
		"is_rental": false,
		"is_rental_return": false,
		"is_emergency": false,
		"requires_own_train": false,
		"required_role": "Driver",
		"assigned_employee_id": "",
		"assigned_train_id": ""
	},
	{
		"id": "job_fixed_002",
		"title": "Return to Depot A",
		"description": "Transport the train back from Depot B to the Depot A.",
		"from_depot": "depot_b",
		"to_depot": "depot_a",
		"reward_money": 400.0,
		"reward_rep": 8,
		"time_limit_days": 0,
		"is_fixed": true,
		"is_rental": false,
		"is_rental_return": false,
		"is_emergency": false,
		"requires_own_train": false,
		"required_role": "Driver",
		"assigned_employee_id": "",
		"assigned_train_id": ""
	}
]

var depot_ids : Array[String] = ["depot_a", "depot_b", "depot_c", "depot_d"]
var depot_names : Dictionary = {
	"depot_a": "Depot A",
	"depot_b": "Depot B",
	"depot_c": "Depot C",
	"depot_d": "Depot D"
}

func _ready() -> void:
	for template in fixed_job_templates:
		availab_jobs.append(template.duplicate())
	
	for i in range(3):
		availab_jobs.append(_generate_random_job())
	
	#print("JobManger: %d Jobs available" % availab_jobs.size())
	
func _generate_random_job() -> Dictionary:
	if randf() < 0.2:
		return _generate_rental_job()
	return _generate_transport_job()
	
func _generate_transport_job() -> Dictionary:
	var from_id = depot_ids[randi() % depot_ids.size()]
	var to_id = _pick_different_depot(from_id)
	
	var reward = randf_range(200.0, 800.0)
	var rep = randi_range(5, 20)
	var days = randi_range(3, 10)
	
	return {
		"id": "job_rand_%d" % Time.get_ticks_msec(),
		"title": "Transport to %s" % depot_names.get(to_id, to_id),
		"description": "A train is waiting at %s - bring it to %s." % [depot_names.get(from_id, from_id), depot_names.get(to_id, to_id)],
		"from_depot": from_id,
		"to_depot": to_id,
		"reward_money": snappedf(reward, 50.0),
		"reward_rep": rep,
		"time_limit_days": days,
		"is_fixed": false,
		"is_rental": false,
		"is_rental_return": false,
		"is_emergency": false,
		"requires_own_train": false,
		"required_role": "Driver",
		"assigned_employee_id": "",
		"assigned_train_id": ""
	}
	
func _generate_rental_job() -> Dictionary:
	var from_id = "depot_a" # HERE::: Own DEPOT -> CHANGE THIS TO CURRENT/ACTIVE DEPOT
	var to_id = _pick_different_depot(from_id)
	
	var monthly_income = snappedf(randf_range(150.0, 500.0), 25.0)
	var days = randi_range(5, 14)
	
	return {
		"id": "job_rental_%d" % Time.get_ticks_msec(),
		"title": "Rent out train to %s" % depot_names.get(to_id, to_id),
		"description": "A client wants to rent one of your trains at %s. Deliver it yourself - no payment for the trip, but you'll earb %s every month while it's rented out." % [depot_names.get(to_id, to_id), NumberFormat.format(monthly_income)],
		"from_depot": from_id,
		"to_id": to_id,
		"reward_money": 0.0,
		"reward_rep": randi_range(2, 8),
		"rental_monthly_income": monthly_income,
		"time_limit_days": days,
		"is_fixed": false,
		"is_rental": true,
		"is_rental_return": false,
		"is_emergency": false,
		"requires_own_train": true,
		"assigned_employee_id": "",
		"assigned_train_id": ""
	}
	
func _generate_emergency_job() -> Dictionary:
	var from_id = depot_ids[randi() % depot_ids.size()]
	var to_id = _pick_different_depot(from_id)
	
	var reward = randf_range(600.0, 1800.0)
	var rep = randi_range(10, 40)
	var days = randi_range(1, 2)
	
	return {
		"id": "job_emergency_%d" % Time.get_ticks_msec(),
		"title": "URGENT: Train needed at %s" % depot_names.get(to_id, to_id),
		"description": "Emergency request! A train at %s must reach %s fast." % [depot_names.get(from_id, from_id), depot_names.get(to_id, to_id)],
		"from_depot": from_id,
		"to_depot": to_id,
		"reward_money": snappedf(reward, 50.0),
		"reward_rep": rep,
		"time_limit_days": days,
		"is_fixed": false,
		"is_rental": false,
		"is_rental_return": false,
		"is_emergency": true,
		"requires_own_train": false,
		"required_role": "Driver",
		"assigned_employee_id": "",
		"assigned_train_id": ""
	}
	
func _pick_different_depot(exclude_id: String) -> String:
	var options = depot_ids.filter(func(d): return d != exclude_id)
	return options[randi() % options.size()]
	
func _maybe_spawn_emergency_job() -> void:
	if randf() < EMERGENCY_CHANCE_PER_DAY:
		availab_jobs.append(_generate_emergency_job())
		jobs_updated.emit()
	
func accept_job(job: Dictionary, employee_id: String = "", train_id: String = "") -> bool:
	if not availab_jobs.has(job):
		return false
	
	var requires_train : bool = job.get("requires_own_train", true)
	
	if requires_train:
		if train_id == "":
			push_warning("JobManager: No train selected!")
			return false
		for active in active_jobs:
			if active.get("assigned_train_id", "") == train_id:
				push_warning("JobManager: Train is already dedicated to another job")
				return false
	else:
		train_id = ""
	
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		if employee.is_empty():
			push_warning("JobManager: Employee '%s' not found" % employee_id)
			return false
		if employee["assigned_job_id"] != "":
			push_warning("JobManager: Employee '%s' is already selected to another job" % employee["name"])
			return false
		var required_role = job.get("required_role")
		if required_role != "" and employee["role"] != required_role:
			push_warning("JobManager: Employee-Role not correct (%s needs %s)" % [employee["name"], required_role])
			return false
	
	availab_jobs.erase(job)
	var active_job = job.duplicate()
	active_job["status"] = JobStatus.ACTIVE
	active_job["assigned_employee_id"] = employee_id
	active_job["assigned_train_id"] = train_id
	_apply_deadline(active_job)
	active_jobs.append(active_job)
	
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		employee["assigned_job_id"] = active_job["id"]
	
	job_accepted.emit(active_job)
	jobs_updated.emit()
	CompanyData.assignment_changed.emit()
	return true
	
func _to_absolute_days(day: int, month: int, year: int) -> int:
	return ((year * 12 + (month - 1)) * DAYS_PER_MONTH) + (day - 1)
	
func _from_absolute_days(total: int) -> Dictionary:
	var day = (total % DAYS_PER_MONTH) + 1
	var months_total = total / DAYS_PER_MONTH
	var month = (months_total % 12) + 1
	var year = months_total / 12
	return {"day": day, "month": month, "year": year}
	
func _apply_deadline(job: Dictionary) -> void:
	var days : int = job.get("time_limit_days", 0)
	if days <= 0:
		job["deadline_day"] = 0
		job["deadline_month"] = 0
		job["deadline_year"] = 0
		return
	
	var total = _to_absolute_days(GameData.current_day, GameData.current_month, GameData.current_year) + days
	var result = _from_absolute_days(total)
	job["deadline_day"] = result["day"]
	job["deadline_month"] = result["month"]
	job["deadline_year"] = result["year"]
	
func check_daily_deadlines(day: int, month: int, year: int) -> void:
	_maybe_spawn_emergency_job()
	
	var today = _to_absolute_days(day, month, year)
	var to_fail : Array[Dictionary] = []
	
	for job in active_jobs:
		var deadline_month : int = job.get("deadline_month", 0)
		if deadline_month == 0:
			continue
		
		var deadline = _to_absolute_days(job.get("deadline_day", 1), deadline_month, job.get("deadline_year", 0))
		if today > deadline:
			to_fail.append(job)
	
	for job in to_fail:
		_fail_job(job)
	
func _fail_job(job: Dictionary) -> void:
	job["status"] = JobStatus.FAILED
	active_jobs.erase(job)
	
	var employee_id = job.get("assigned_employee_id", "")
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		if not employee.is_empty():
			employee["assigned_job_id"] = ""
			employee["performance"] = clampf(employee["performance"] - 8.0, 0, 100)
	
	reputation = max(0, reputation - int(job.get("reward_rep", 0) / 2))
	
	job_failed.emit(job)
	jobs_updated.emit()
	CompanyData.assignment_changed.emit()
	
func reassign_employee(job_id: String, new_employee_id: String) -> bool:
	var job = _find_active_job(job_id)
	if job.is_empty():
		return false
	
	var required_role = job.get("required_role", "")
	
	if new_employee_id != "":
		var new_employee = CompanyData.get_employee(new_employee_id)
		if new_employee.is_empty() or new_employee["assigned_job_id"] != "":
			return false
		if required_role != "" and new_employee["role"] != required_role:
			push_warning("JobManager: Role is not suitable for this job")
			return false
	
	var old_id = job.get("assigned_employee_id", "")
	if old_id != "":
		var old_employee = CompanyData.get_employee(old_id)
		if not old_employee.is_empty():
			old_employee["assigned_job_id"] = ""
	
	job["assigned_employee_id"] = new_employee_id
	if new_employee_id != "":
		CompanyData.get_employee(new_employee_id)["assigned_job_id"] = job_id
	
	jobs_updated.emit()
	CompanyData.assignment_changed.emit()
	return true
	
func _find_active_job(job_id: String) -> Dictionary:
	for job in active_jobs:
		if job["id"] == job_id:
			return job
	return {}
	
func notify_depot_arrived(depot_id: String, train: Node) -> void:
	var arrived_train_id = train.get("entity_id") if train.get("entity_id") != null else ""
	
	for job in active_jobs:
		if job.get("status") != JobStatus.ACTIVE:
			continue
		if job.get("to_depot") != depot_id:
			continue
		
		var requires_train : bool = job.get("requires_own_train", true)
		if requires_train and job.get("assigned_train_id", "") != arrived_train_id:
			continue
		
		_complete_job(job, train)
	
func _complete_job(job: Dictionary, train: Node) -> void:
	job["status"] = JobStatus.COMPLETED
	active_jobs.erase(job)
	
	var employee_id = job.get("assigned_employee_id", "")
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		if not employee.is_empty():
			employee["assigned_job_id"] = ""
			employee["performance"] = clampf(employee["performance"] + 3.0, 0, 100)
	
	var bonus_rep := 0
	var days_early := 0
	if job.get("deadline_month", 0) > 0:
		var today = _to_absolute_days(GameData.current_day, GameData.current_month, GameData.current_year)
		var deadline = _to_absolute_days(job["deadline_day"], job["deadline_month"], job["deadline_year"])
		days_early = deadline - today
		if days_early > 0:
			bonus_rep = min(days_early * EARLY_BONUS_REP_PER_DAY, EARLY_BOMUS_REP_CAP)
	job["bonus_rep"] = bonus_rep
	job["days_early"] = days_early
	
	if job.get("is_rental_return", false):
		rented_trains = rented_trains.filter(func(r): return r["train_id"] != job.get("assigned_train_id", ""))
		print("JoManager: Rental return succesfull")
	elif job.get("is_rental", false):
		rented_trains.append({
			"train_id": job.get("assigned_train_id", ""),
			"monthly_income": job.get("rental_monthly_income", 0.0),
			"depot": job.get("to_depot", ""),
			"origin_depot": job.get("from_depot", ""),
			"months_remaining": job.get("rental_duration_months", 3),
			"contract_ended": false,
			"return_job_created": false,
			"penalty_per_month": 100.0
		})
	else:
		GameData.add_cash(job.get("reward_money", 0.0), "Payment for job")
	
	reputation += job.get("reward_rep", 0) + bonus_rep
	completed_jobs.append(job)
	
	job_completed.emit(job)
	jobs_updated.emit()
	CompanyData.assignment_changed.emit()
	
	if not job.get("is_fixed", false) and not job.get("is_emergency", false) and not job.get("is_rental_return", false):
		availab_jobs.append(_generate_random_job())
		jobs_updated.emit()
	
func process_rental_contracts() -> void:
	var income_total := 0.0
	var penalty_total := 0.0
	
	for r in rented_trains:
		if r.get("contract_ended", false):
			if not r.get("return_job_created", false):
				_create_return_job(r)
				r["return_job_created"] = true
			else:
				penalty_total += r.get("penalty_per_month", 100.0)
		else:
			income_total += r["monthly_income"]
			r["months_remaining"] -= 1
			if r["months_remaining"] <= 0:
				r["contract_ended"] = true
	
	if income_total > 0:
		GameData.add_cash(int(income_total), "Train Rental Income")
		rental_income_paid.emit(income_total)
	
	if penalty_total > 0:
		GameData.add_cash(-int(penalty_total), "Late Rental Return Penalty")
		rental_penalty_paid.emit(penalty_total)
	
func _create_return_job(rental: Dictionary) -> void:
	var return_job := {
		"id": "job_return_%d" % Time.get_ticks_msec(),
		"title": "Return rented train from %s" % depot_names.get(rental["depot"], "?"),
		"description": "Rental contract ended - bring your train back from %s, or you'll be fined monthly until you do." % [depot_names.get(rental["depot"], "?"), depot_names.get(rental["origin_depot"], "?")],
		"from_depot": rental["depot"],
		"to_depot": rental["origin_depot"],
		"reward_money": 0.0,
		"reward_rep": 0,
		"deadline_day": 0,
		"deadline_month": 0,
		"deadline_year": 0,
		"is_fixed": false,
		"is_rental": false,
		"is_rental_return": true,
		"is_emergency": false,
		"requires_own_train": true,
		"required_role": "Driver",
		"assigned_employee_id": "",
		"assigned_train_id": rental["train_id"],
		"status": JobStatus.ACTIVE
	}
	active_jobs.append(return_job)
	jobs_updated.emit()
	
func release_job_for_employee(employee_id: String) -> void:
	for job in active_jobs:
		if job.get("assigned_job_id", "") == employee_id:
			job["assigned_employee_id"] = ""
			jobs_updated.emit()
			CompanyData.assignment_changed.emit()
			return
	
func get_available_jobs() -> Array:
	return availab_jobs
	
func get_active_jobs() -> Array:
	return active_jobs
	
func get_available_trains() -> Array:
	var used_ids := []
	for job in active_jobs:
		var tid = job.get("assigned_train_id", "")
		if tid != "":
			used_ids.append(tid)
	for r in rented_trains:
		used_ids.append(r["train_id"])
	
	var all_trains_in_group = get_tree().get_nodes_in_group("train")
	print("DEBUG - Trains in Gruppe 'train': ", all_trains_in_group.size())
	for t in all_trains_in_group:
		print("  - Name: ", t.name, " | entity_id: '", t.get("entity_id"), "'")
	
	var result := []
	for train in get_tree().get_nodes_in_group("train"):
		var tid = train.get("entity_id") if train.get("entity_id") != null else ""
		if tid != "" and not used_ids.has(tid):
			result.append(train)
	return result
	
func get_status() -> Dictionary:
	return {
		"money": GameData.cash,
		"reputation": reputation,
		"completed": completed_jobs.size()
	}
	
