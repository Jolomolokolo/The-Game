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
		
	var jobs = JobManager.get_available_jobs()
	if jobs.is_empty():
		_add_empty_label(available_jobs_list, "No jobs available right now")
		return
	
	for job in jobs:
		_add_available_job_card(job)
	
func _rebuild_active_list() -> void:
	for child in active_jobs_list.get_children():
		child.queue_free()
	
	var jobs = JobManager.get_active_jobs()
	if jobs.is_empty():
		_add_empty_label(active_jobs_list, "No active jobs")
		return
	
	for job in jobs:
		_add_active_job_card(job)
	
func _add_empty_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_MUTED)
	parent.add_child(label)
	
func _build_card_base(parent: VBoxContainer, job: Dictionary, bg_color: Color) -> VBoxContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var title_label := Label.new()
	title_label.text = job.get("title", "Job")
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	if job.get("is_fixed", false):
		var badge := Label.new()
		badge.text = "FIXED"
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", COLOR_MUTED)
		header.add_child(badge)
	
	var desc_label := Label.new()
	desc_label.text = job.get("description", "")
	desc_label.add_theme_color_override("font_color", COLOR_MUTED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	var route_label := Label.new()
	var from
	
	
	
