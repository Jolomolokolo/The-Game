extends Node

signal job_completed(job)
signal job_accepted(job)
signal job_failed(job)
signal jobs_updated

enum JobStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED}

var availab_jobs : Array[Dictionary] = []
var active_jobs : Array[Dictionary] = []
var completed_jobs : Array[Dictionary] = []

var reputation : int = 0

var fixed_job_templates : Array[Dictionary] = [
	{
		"id": "job_fixed_001",
		"title": "Express train to Depot B",
		"description": "Transport the train from Depot A to the Depot B.",
		"from_depot": "depot_a",
		"to_depot": "depot_b",
		"reward_money": 500.0,
		"reward_rep": 10,
		"time_limit": 0,
		"is_fixed": true,
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
		"time_limit": 0,
		"is_fixed": true,
		"assigned_employee_id": "",
		"assigned_train_id": ""
	}
]

var depot_ids : Array[String] = ["depot_a", "depot_b", "depot_c"]
var depot_names : Dictionary = {
	"depot_a": "Depot A",
	"depot_b": "Depot B",
	"depot_c": "Depot C"
}

func _ready() -> void:
	for template in fixed_job_templates:
		availab_jobs.append(template.duplicate())
	
	for i in range(3):
		availab_jobs.append(_generate_random_job())
	
	print("JobManger: %d Jobs available" % availab_jobs.size())
	
func _generate_random_job() -> Dictionary:
	var from_idx = randi() % depot_ids.size()
	var to_idx = (from_idx + 1 + randi() % (depot_ids.size() - 1)) % depot_ids.size()
	
	var from_id = depot_ids[from_idx]
	var to_id = depot_ids[to_idx]
	
	var reward = randf_range(200.0, 800.0)
	var rep = randi_range(5, 20)
	
	return {
		"id": "job_rand_%d" % Time.get_ticks_msec(),
		"title": "Transport to %s" % depot_names.get(to_id, to_id),
		"description": "Transport from %s to %s" % [
			depot_names.get(from_id, from_id),
			depot_names.get(to_id, to_id)
		],
		"from_depot": from_id,
		"to_depot": to_id,
		"reward_money": snappedf(reward, 50.0),
		"reward_rep": rep,
		"time_limit": 0,
		"is_fixed": false,
		"assigned_employee_id": "",
		"assigned_train_id": ""

	}
	
func accept_job(job: Dictionary, employee_id: String = "", train_id: String = "") -> bool:
	if not availab_jobs.has(job):
		return false
	
	if train_id == "":
		push_warning("JobManager: No train selected!")
		return false
	
	for active in active_jobs:
		if active.get("assigned_train_id", "") == train_id:
			push_warning("JobManager: Train is already selected to another job")
			return false
	
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		if employee.is_empty():
			push_warning("JobManager: Employee '%s' not found" % employee_id)
			return false
		if employee["assigned_job_id"] != "":
			push_warning("JobManager: Employee '%s' is already selected to another job" % employee["name"])
			return false
	
	availab_jobs.erase(job)
	var active_job = job.duplicate()
	active_job["status"] = JobStatus.ACTIVE
	active_job["assigned_employee_id"] = employee_id
	active_job["assigned_train_id"] = train_id
	active_jobs.append(active_job)
	
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		employee["assigned_job_id"] = active_job["id"]
		print("JobManager: Job accepted: %s (Train: %s, Employee: %s)" % [job.title, train_id, employee["name"]])
	else:
		print("JobManager: Job accepted: %s (Train: %s, self-driven)" % [job.title, train_id])
	
	job_accepted.emit(active_job)
	jobs_updated.emit()
	CompanyData.assignment_changed.emit()
	return true
	
func notify_depot_arrived(depot_id: String, train: Node) -> void:
	var arrived_train_id = train.get("entity_id") if train.get("entity_id") != null else ""
	
	for job in active_jobs:
		if job.get("status") != JobStatus.ACTIVE:
			continue
		if job.get("to_depot") != depot_id:
			continue
		if job.get("assigned_train_id", "") != arrived_train_id:
			continue
		_complete_job(job, train)
	
func _complete_job(job: Dictionary, train: Node) -> void:
	job["status"] = JobStatus.COMPLETED
	active_jobs.erase(job)
	completed_jobs.append(job)
	
	var employee_id = job.get("assigned_employee_id", "")
	if employee_id != "":
		var employee = CompanyData.get_employee(employee_id)
		if not employee.is_empty():
			employee["assigned_job_id"] = ""
			employee["performance"] = clampf(employee["performance"] + 3.0, 0, 100)
	
	GameData.add_cash(job.get("reward_money", 0.0), "Payment for job")
	reputation += job.get("reward_rep", 0)
	
	emit_signal("job_completed", job)
	emit_signal("jobs_updated")
	CompanyData.assignment_changed.emit()
	
	print("JobManager: Job completed: %s | +$%.0f | +%d Rep" % [job.title, job.get("reward_money", 0), job.get("reward_rep", 0)])
	 
	if not job.get("is_fixed", false):
		availab_jobs.append(_generate_random_job())
		emit_signal("jobs_updated")
	
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
	
