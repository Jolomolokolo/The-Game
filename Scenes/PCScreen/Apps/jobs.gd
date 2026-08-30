extends VBoxContainer

@onready var money_label = $StatusBar/MoneyLabel
@onready var reputation_label = $StatusBar/ReputationLabel
@onready var completed_label = $StatusBar/CompletedLabel

@onready var available_jobs_list: VBoxContainer = $HBoxContainer/AvailableScroll/AvailableJobsList
@onready var active_jobs_list: VBoxContainer = $HBoxContainer/ActiveScroll/ActiveJobsList

const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)
const COLOR_REWARD := Color(0.30, 0.85, 0.45)
const COLOR_REP := Color(0.65, 0.50, 0.95)
const COLOR_WARNING := Color(0.95, 0.75, 0.25)
const COLOR_URGENT := Color(0.92, 0.35, 0.35)
const COLOR_ROW_BG := Color(0.078, 0.098, 0.145, 0.6)
const COLOR_ACTIVE_BG := Color(0.1, 0.13, 0.1, 0.6)
const COLOR_RENTAL_BG := Color(0.10, 0.10, 0.14, 0.6)

const MONTH_NAMES := [
	"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
]

func _ready() -> void:
	JobManager.jobs_updated.connect(_refresh_all)
	CompanyData.assignment_changed.connect(_refresh_all)
	CompanyData.employee_hired.connect(func(_e): _refresh_all())
	CompanyData.employee_fired.connect(func(_e): _refresh_all())
	
	visibility_changed.connect(func():
		if visible:
			_refresh_all()
	)
	
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
	if job.get("is_emergency", false):
		style.border_width_bottom = 3
		style.border_color = COLOR_URGENT
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
	
	if job.get("is_emergency", false):
		var badge := Label.new()
		badge.text = "URGENT"
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", COLOR_URGENT)
		header.add_child(badge)
	elif job.get("is_rental", false):
		var badge := Label.new()
		badge.text = "RENTAL"
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", COLOR_MUTED)
		header.add_child(badge)
	elif job.get("is_fixed"):
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
	var from_name = JobManager.depot_names.get(job.get("from_depot", ""), "?")
	var to_name = JobManager.depot_names.get(job.get("to_depot", ""), "?")
	var role_text = " | Role: %s" % job.get("required_role", "") if job.get("required_role", "") != "" else ""	
	route_label.text = "%s -> %s%s" % [from_name, to_name, role_text]
	vbox.add_child(route_label)
	
	if job.get("is_rental", false):
		var income_label := Label.new()
		income_label.text = "No upfront payment - %s/month once delivered" % NumberFormat.format(job.get("rental_monthly_income", 0.0))
		income_label.add_theme_color_override("font_color", COLOR_REWARD)
		vbox.add_child(income_label)
	else:
		var reward_label := Label.new()
		reward_label.text = "%s  +%d Rep" % [NumberFormat.format(job.get("reward_money", 0.0)), job.get("reward_rep", 0)]
		reward_label.add_theme_color_override("font_color", COLOR_REWARD)
		vbox.add_child(reward_label)
	
	if job.get("time_limit_days", 0) > 0:
		var deadline_label := Label.new()
		if job.has("deadline_month") and job["deadline_month"] > 0:
			deadline_label.text = "Deadline: %s %d, %d" % [MONTH_NAMES[job["deadline_month"]], job["deadline_day"], job["deadline_year"]]
		else:
			deadline_label.text = "Time limit: %d days" % job["time_limit_days"]
		deadline_label.add_theme_color_override("font_color", COLOR_URGENT if job.get("is_emergency", false) else COLOR_WARNING)
		vbox.add_child(deadline_label)
	
	return vbox
	
	# HIER WEITER MACHEN
	
func _add_available_job_card(job: Dictionary) -> void:
	var vbox = _build_card_base(available_jobs_list, job, COLOR_ROW_BG)
	var required_role = job.get("required_role", "")
	var requires_own_train : bool = job.get("requires_own_train", true)
	
	var available_trains = JobManager.get_available_trains() if requires_own_train else []
	
	var train_dropdown : OptionButton = null
	if requires_own_train:
		var train_row := HBoxContainer.new()
		train_row.add_theme_constant_override("separation", 8)
		vbox.add_child(train_row)
		
		var train_label := Label.new()
		train_label.text = "Train:"
		train_label.add_theme_color_override("font_color", COLOR_MUTED)
		train_row.add_child(train_label)
		
		train_dropdown = OptionButton.new()
		train_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if available_trains.is_empty():
			train_dropdown.add_item("No trains available")
			train_dropdown.disabled = true
		else:
			for train in available_trains:
				train_dropdown.add_item(train.name)
	
	var available_employees = CompanyData.get_available_employees()
	
	var train_row := HBoxContainer.new()
	train_row.add_theme_constant_override("separation", 8)
	vbox.add_child(train_row)
	
	var train_label := Label.new()
	train_label.text = "Train:"
	train_label.add_theme_color_override("font_color", COLOR_MUTED)
	train_row.add_child(train_label)
	
	if available_trains.is_empty():
		train_dropdown.add_item("No trains available")
		train_dropdown.disabled = true
	else:
		for train in available_trains:
			train_dropdown.add_item(train.name)
	train_row.add_child(train_dropdown)
	
	var assign_row := HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 8)
	vbox.add_child(assign_row)
	
	var employee_dropdown := OptionButton.new()
	employee_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	employee_dropdown.add_item("Drive it yourself")
	for employee in available_employees:
		employee_dropdown.add_item("%s (%s)" % [employee["name"], employee["role"]])
	assign_row.add_child(employee_dropdown)
	
	var accept_button := Button.new()
	accept_button.text = "Accept"
	accept_button.disabled = available_trains.is_empty()
	accept_button.pressed.connect(func():
		if available_trains.is_empty():
			return
		var selected_train = available_trains[train_dropdown.selected]
		var train_entity_id : String = selected_train.entity_id
		
		var selected_employee_index = employee_dropdown.selected
		if selected_employee_index == 0:
			JobManager.accept_job(job, "", train_entity_id)
		else:
			var selected_employee = available_employees[selected_employee_index - 1]
			JobManager.accept_job(job, selected_employee["id"], train_entity_id)
	)
	assign_row.add_child(accept_button)
	
func _add_active_job_card(job: Dictionary) -> void:
	var vbox = _build_card_base(active_jobs_list, job, COLOR_ACTIVE_BG)
	
	var employee_id = job.get("assigned_employee_id", "")
	var train_id = job.get("assigned_train_id", "")
	
	var driver_text := "Driven by you" if employee_id == "" else _get_employee_name(employee_id)
	
	var train_name := "?"
	for train in get_tree().get_nodes_in_group("train"):
		if train.get("entity_id") == train_id:
			train_name = train.name
			break
	
	var status_label := Label.new()
	status_label.text = "In Progress -> %s | Train: %s" % [driver_text, train_name]
	status_label.add_theme_color_override("font_color", COLOR_REP)
	vbox.add_child(status_label)
	
func _get_employee_name(employee_id: String) -> String:
	var employee = CompanyData.get_employee(employee_id)
	return employee["name"] if not employee.is_empty() else "?"
	
