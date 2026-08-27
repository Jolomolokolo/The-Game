extends VBoxContainer

@onready var month_label : Label = $Header/MonthLabel
@onready var calendar_grid : GridContainer = $ContentRow/CalendarGrid
@onready var selected_day_label : Label = $ContentRow/SidePanel/SelectedDayLabel
@onready var day_off_list : VBoxContainer = $ContentRow/SidePanel/DayOffScroll/DayOffList
@onready var active_jobs_list : VBoxContainer = $ContentRow/SidePanel/ActiveJobsScroll/ActiveJobsList

const COLOR_MUTED := Color(0.55, 0.6, 0.68)
const COLOR_TODAY := Color(0.25, 0.65, 0.7)
const COLOR_HAS_EVENT := Color(0.95, 0.75, 0.25)
const COLOR_DAY_BG := Color(0.078, 0.098, 0.145, 0.6)
const COLOR_DAY_BG_SELECTED := Color(0.10, 0.16, 0.18, 0.9)

const MONTH_NAMES := [
	"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
]
@onready var DAYS_IN_MONTH = JobManager.DAYS_PER_MONTH

var selected_day : int = 1
var _day_buttons : Dictionary = {}

func _ready() -> void:
	CompanyData.company_data_updated.connect(_refresh_all)
	GameData.finances_updated.connect(_refresh_all)
	JobManager.jobs_updated.connect(_refresh_all)
	
	selected_day = 1
	_refresh_all()
	
func _refresh_all() -> void:
	month_label.text = "%s %d" % [MONTH_NAMES[GameData.current_month], GameData.current_year]
	_rebuild_grid()
	_rebuild_side_panel()
	
func _rebuild_grid() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()
	_day_buttons.clear()
	
	for day in range(1, DAYS_IN_MONTH + 1):
		var has_event = _day_has_any_event(day)
		var btn := Button.new()
		btn.text = str(day)
		
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		btn.custom_minimum_size = Vector2(0, 40)
		btn.toggle_mode = true
		btn.button_pressed = (day == selected_day)
		
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_DAY_BG_SELECTED if day == selected_day else COLOR_DAY_BG
		style.set_corner_radius_all(6)
		if has_event:
			style.border_width_bottom = 3
			style.border_color = COLOR_HAS_EVENT
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)
		
		btn.pressed.connect(_on_day_selected.bind(day))
		calendar_grid.add_child(btn)
		_day_buttons[day] = btn
	
func _day_has_any_event(day: int) -> bool:
	for e in CompanyData.employees:
		for off in e["days_off"]:
			if off["month"] == GameData.current_month and off["year"] == GameData.current_year and off["day"] == day:
				return true
	return false
	
func _on_day_selected(day: int) -> void:
	selected_day = day
	_rebuild_grid()
	_rebuild_side_panel()
	
func _rebuild_side_panel() -> void:
	selected_day_label.text = "%s %d, %d" % [MONTH_NAMES[GameData.current_month], selected_day, GameData.current_year]
	
	for child in day_off_list.get_children():
		child.queue_free()
	
	var employees_off : Array = []
	for e in CompanyData.employees:
		for off in e["days_off"]:
			if off["month"] == GameData.current_month and off["year"] == GameData.current_year and off["day"] == selected_day:
				employees_off.append(e)
	
	if employees_off.is_empty():
		_add_muted_label(day_off_list, "No one is off today")
	else:
		for e in employees_off:
			_add_muted_label(day_off_list, "Off: %s (%s)" % [e["name"], e["role"]])
	
	_rebuild_active_jobs()
	
func _rebuild_active_jobs() -> void:
	for child in active_jobs_list.get_children():
		child.queue_free()
	
	var jobs = JobManager.get_active_jobs()
	if jobs.is_empty():
		_add_muted_label(active_jobs_list, "No active jobs")
		return
	
	for job in jobs:
		var employee_id = job.get("assigned_employee_id", "")
		var driver = "you" if employee_id == "" else _get_employee_name(employee_id)
		_add_muted_label(active_jobs_list, "Job: %s (%s)" % [job["title"], driver])
	
func _get_employee_name(employee_id: String) -> String:
	var e = CompanyData.get_employee(employee_id)
	return e["name"] if not e.is_empty() else "?"
	
func _add_muted_label(parent: VBoxContainer, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(label)
	
