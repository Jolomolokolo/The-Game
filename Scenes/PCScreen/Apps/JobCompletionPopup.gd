extends CanvasLayer

@export var display_duration := 4.0
@export var fade_duration := 0.3

var _panel : PanelContainer
var _title_label : Label
var _reward_label : Label
var _rep_label : Label
var _bonus_label : Label
var _close_button : Button
var _active_tween : Tween

const COLOR_REWARD := Color(0.30, 0.85, 0.45)
const COLOR_REP := Color(0.65, 0.50, 0.95)
const COLOR_BONUS := Color(0.95, 0.75, 0.25)
const COLOR_MUTED := Color(0.541, 0.584, 0.647, 1.0)

func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	JobManager.job_completed.connect(_on_job_completed)
	
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.modulate.a = 0.0
	_panel.custom_minimum_size = Vector2(320, 0)
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.position += Vector2(0, 60)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.078, 0.098, 0.145, 0.97)
	style.set_corner_radius_all(12)
	style.set_expand_margin_all(16)
	style.border_width_bottom = 3
	style.border_color = COLOR_REWARD
	style.shadow_size = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)
	
	var header := HBoxContainer.new()
	vbox.add_child(header)
	
	var check_label := Label.new()
	check_label.text = "Job Complete"
	check_label.add_theme_font_size_override("font_size", 14)
	check_label.add_theme_color_override("font_color", COLOR_MUTED)
	check_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(check_label)
	
	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(24, 24)
	_close_button.pressed.connect(_hide_now)
	header.add_child(_close_button)
	
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 17)
	_title_label.autowrap_mod = TextServer.AUTOWRAP_WORD
	vbox.add_child(_title_label)
	
	_reward_label = Label.new()
	_reward_label.add_theme_color_override("font_color", COLOR_REWARD)
	vbox.add_child(_reward_label)
	
	_rep_label = Label.new()
	_rep_label.add_theme_color_override("font_color", COLOR_REP)
	vbox.add_child(_rep_label)
	
	_bonus_label = Label.new()
	_bonus_label.add_theme_color_override("font_color", COLOR_BONUS)
	_bonus_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_bonus_label)
	
func _on_job_completed(job: Dictionary) -> void:
	_title_label.text = job.get("title", "Job")
	
	if job.get("is_rental", false):
		_reward_label.text = "Now earning %s/month" % NumberFormat.format(job.get("rental_monhtly_income", 0.0))
	elif job.get("is_rental_return", false):
		_reward_label.text = "Train returned successfully"
	else:
		_reward_label.text = "+%s" % NumberFormat.format(job.get("reward_money", 0.0))
	
	_rep_label.text = "+%d Reputation" % job.get("reward_rep", 0)
	
	var bonus_rep : int = job.get("bonus_rep", 0)
	if bonus_rep > 0:
		var days_early : int = job.get("days_early", 0)
		_bonus_label.text = "Completed %d day%s early: +%d bonus Rep!" % [days_early, ("s" if days_early != 1 else ""), bonus_rep]
		_bonus_label.visible = true
	else:
		_bonus_label.visible = false
	
	_show()
	
func _show() -> void:
	if _active_tween:
		_active_tween.kill()
	
	_active_tween = create_tween()
	_active_tween.tween_property(_panel, "modulate:a", 1.0, fade_duration)
	_active_tween.tween_interval(display_duration)
	_active_tween.tween_property(_panel, "modulate:a", 0.0, fade_duration)
	
func _hide_now() -> void:
	if _active_tween:
		_active_tween.kill()
	_panel.modulate.a = 0.0
	
