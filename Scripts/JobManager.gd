extends Node

signal job_completed(job)
signal job_accepted(job)
signal job_failed(job)
signal jobs_updated

enum JobStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED}

var availab_jobs : Array[Dictionary] = []
var active_jobs : Array[Dictionary] = []
var completed_jobs : Array[Dictionary] = []

var money : float = 0.0
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
		"is_fixed": true
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
		"is_fixed": true
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
		"is_fixed": false
	}
	
func accept_job(job: Dictionary) -> bool:
	if not availab_jobs.has(job):
		return false
	availab_jobs.erase(job)
	var active_job = job.duplicate()
	active_job["status"] = JobStatus.ACTIVE
	active_jobs.append(active_job)
	emit_signal("job_accepted", active_job)
	emit_signal("jobs_updated")
	print("JobManager: Job accepted: %s" % job.title)
	return true
	
func notify_depot_arrived(depot_id: String, train: Node) -> void:
	for job in active_jobs:
		if job.get("status") != JobStatus.ACTIVE:
			continue
		if job.get("to_depot") == depot_id:
			_complete_job(job, train)
	
func _complete_job(job: Dictionary, train: Node) -> void:
	job["status"] = JobStatus.COMPLETED
	active_jobs.erase(job)
	completed_jobs.append(job)
	
	GameData.add_cash(job.get("reward_money", 0.0), "Payment for job")
	reputation += job.get("reward_rep", 0)
	
	emit_signal("job_completed", job)
	emit_signal("jobs_updated")
	
	print("JobManager: Job completed: %s | +$%.0f | +%d Rep" % [job.title, job.get("reward_money", 0), job.get("reward_rep", 0)])
	 
	if not job.get("is_fixed", false):
		availab_jobs.append(_generate_random_job())
		emit_signal("jobs_updated")
	
func get_available_jobs() -> Array:
	return availab_jobs
	
func get_active_jobs() -> Array:
	return active_jobs
	
func get_status() -> Dictionary:
	return {
		"money": GameData.cash,
		"reputation": reputation,
		"completed": completed_jobs.size()
	}
	
