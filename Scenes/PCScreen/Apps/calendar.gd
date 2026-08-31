extends VBoxContainer

@onready var month_label : Label = $Header/MonthLabel
@onready var calendar_grid : GridContainer = $ContentRow/CalendarGrid
@onready var selected_day_label : Label = $ContentRow/SidePanel/SelectedDayLabel
@onready var day_events_list : VBoxContainer = $ContentRow/SidePanel/DayEventsScroll/DayEventsList
@onready var upcoming_list : VBoxContainer = $ContentRow/SidePanel/UpcomingScroll/UpcomingList

const COLOR_MUTED := Color(0.55, 0.6, 0.68)
const COLOR_TODAY_BORDER := Color(0.25, 0.65, 0.7)
const COLOR_DEADLINE := Color(0.95, 0.75, 0.25)
const COLOR_URGENT := Color(0.92, 0.35, 0.35)
const COLOR_DAY_OFF := Color(0.65, 0.5, 0.95)
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
	
	for day in range(1, DAYS_IN_MONTH + 1):
		var urgency = _day_urgency(day)
		var is_today = (day == GameData.current_day)
		
		var btn := Button.new()
		btn.text  = str(day)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_pressed = (day == selected_day)
		
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_DAY_BG_SELECTED if day == selected_day else COLOR_DAY_BG
		style.set_corner_radius_all(6)
		
		if is_today:
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_color = COLOR_TODAY_BORDER
		
		if urgency == "urgent":
			style.border_width_bottom = 3
			style.border_color = COLOR_URGENT
		elif urgency == "deadline":
			style.border_width_bottom = 3
			style.border_color = COLOR_DEADLINE
		elif urgency == "dayoff":
			style.border_width_bottom = 3
			style.border_color = COLOR_DAY_OFF
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.pressed.connect(_on_day_selected.bind(day))
		calendar_grid.add_child(btn)
	
func _day_urgency(day: int) -> String:
	var has_deadline := false
	var has_urgent := false
	
	for job in JobManager.get_active_jobs():
		if job.get("deadline_month", 0) != GameData.current_month:
			continue
		if job.get("deadline_year", 0) != GameData.current_year:
			continue
		if job.get("deadline_day", 0) != GameData.current_day:
			continue
		has_deadline = true
		if job.get("is_emergency", false):
			has_urgent = true
	
	if has_urgent:
		return "urgent"
	if has_deadline:
		return "deadline"
	
	for e in CompanyData.employees:
		for off in e["days_off"]:
			if off["month"] == GameData.current_month and off["year"] == GameData.current_year and off["day"] == day:
				return "dayoff"
	
	return "none"
	
func _on_day_selected(day: int) -> void:
	selected_day = day
	_rebuild_grid()
	_rebuild_side_panel()
	
func _rebuild_side_panel() -> void:
	var suffix = " (Today)" if selected_day == GameData.current_day else ""
	selected_day_label.text= "%s %d, %d%s" % [MONTH_NAMES[GameData.current_month], selected_day, GameData.current_year, suffix]
	
	for child in day_events_list.get_children():
		child.queue_free()
	
	var found_anything := false
	
	for job in JobManager.get_active_jobs():
		if job.get("deadline_month", 0) != GameData.current_month:
			continue
		if job.get("deadline_year", 0) != GameData.current_year:
			continue
		if job.get("deadline_day", 0) != selected_day:
			continue
		found_anything = true
		var icon = "⚠" if job.get("is_emergency", false) else "🚂"
		var color = COLOR_URGENT if job.get("is_emergency", false) else COLOR_DEADLINE
		_add_event_label(day_events_list, "%s Due: %s" % [icon, job["title"]], color)
	
	for e in CompanyData.employees:
		for off in e["days_off"]:
			if off["month"] == GameData.current_month and off["year"] == GameData.current_year and off["day"] == selected_day:
				found_anything = true
				_add_event_label(day_events_list, "%s (%s) is off" % [e["name"], e["role"]], COLOR_DAY_OFF)
	 
	if not found_anything:
		_add_event_label(day_events_list, "Nothing scheduled", COLOR_MUTED)
	
	_rebuild_upcoming() 
	
func _rebuild_upcoming() -> void:
	for child in upcoming_list.get_children():
		child.queue_free()
	
	var jobs_with_deadline = JobManager.get_active_jobs().filter(func(j): return j.get("deadline_month", 0) > 0)
	
	if jobs_with_deadline.is_empty():
		_add_event_label(upcoming_list, "No upcoming deadlines", COLOR_MUTED)
		return
	
	jobs_with_deadline.sort_custom(func(a, b):
		var a_key = a["deadline_year"] * 180 + a["deadline_month"] * 15 + a["deadline_day"]
		var b_key = b["deadline_year"] * 180 + a["deadline_month"] * 15 + a["deadline_day"]
		return a_key < b_key
		)
	
	for job in jobs_with_deadline:
		var icon = "⚠" if job.get("is_emergency", false) else "🚂"
		var color = COLOR_URGENT if job.get("is_emergency", false) else COLOR_DEADLINE
		var text = "%s %s - %s %d" % [icon, job["title"], MONTH_NAMES[job["deadline_month"]].substr(0, 3), job["deadline_day"]]
		_add_event_label(upcoming_list, text, color)
	
func _add_event_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(label)
	
