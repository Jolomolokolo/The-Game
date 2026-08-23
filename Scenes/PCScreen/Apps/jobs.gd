extends VBoxContainer

@onready var money_label = $StatusBar/MoneyLabel
@onready var reputation_label = $StatusBar/ReputationLabel
@onready var completed_label = $StatusBar/CompletedLabel

@onready var available_jobs_list: VBoxContainer = $AvailableScroll/AvailableJobsList
@onready var active_jobs_list: VBoxContainer = $ActiveScroll/ActiveJobsList

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_REWARD := Color(0.30, 0.85, 0.45)
const COLOR_REP := Color(0.65, 0.50, 0.95)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)
const COLOR_ACTIVE_BG := Color(0.1, 0.13, 0.1, 0.6)

func _ready() -> void:
	JobManager.jobs_updated.connect(_refresh_all)
	CompanyData.assignment_changed.connect(_refresh_all)
	CompanyData.employee_hired.connect(func(_e): _refresh_all())
	CompanyData.employee_fired.connect(func(_e): _refresh_all())
	_refresh_all()
	
func _refresh_all() -> void:
	var status = JobManager.get_status()
	money_label.text = "Cash: %s" % NumberFormat.format(status["money"]) # ???
	reputation_label.text = "Reputation: %d" % status["reputation"]
	completed_label.text = "Completed: %d" % status["completed"]
	
	_rebuild_available_list()
	_rebuild_active_list()
	
func _rebuild_available_list() -> void:
	for child in available_jobs_list.get_children():
		child.queue_free()
