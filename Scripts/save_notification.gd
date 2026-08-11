extends CanvasLayer

@export var display_duration := 0.5
@export var fade_duration := 0.12
@export var bar_fill_duration := 0.2

const SAVE_COLOR := Color(0.4, 0.85, 0.5)
const LOAD_COLOR := Color(0.45, 0.65, 0.95)

var _panel : PanelContainer
var _title_label : Label
var _progress_bar : ProgressBar
var _accent_bar : ColorRect
var _active_tween : Tween

func _ready() -> void:
	layer = 129
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	
	SaveManager.save_completed.connect(func(_slot): _show_message("Game Saved", SAVE_COLOR))
	SaveManager.load_completed.connect(func(_slot): _show_message("Game loaded", LOAD_COLOR))
	
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.modulate.a = 0.0
	_panel.custom_minimum_size = Vector2(260, 0)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.position += Vector2(24, -24)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	style.shadow_size = 6
	style.shadow_color = Color(0, 0, 0, 0.3)
	_panel.add_theme_stylebox_override("panel", style)
	
	add_child(_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("seperation", 8)
	_panel.add_child(vbox)
	
	var header := HBoxContainer.new()
	header.add_theme_constant_override("seperation", 10)
	vbox.add_child(header)
	
	_accent_bar = ColorRect.new()
	_accent_bar.custom_minimum_size = Vector2(4, 20)
	header.add_child(_accent_bar)
	
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_title_label)
	
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(_progress_bar)
	
func _show_message(text: String, accent_color: Color) -> void:
	_title_label.text = text
	_accent_bar.color = accent_color
	_progress_bar.value = 0.0
	
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = accent_color
	bar_style.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("fill", bar_style)
	
	if _active_tween:
		_active_tween.kill()
	
	_active_tween = create_tween()
	_active_tween.tween_property(_panel, "modulate:a", 1.0, fade_duration)
	_active_tween.parallel().tween_property(_progress_bar, "value", 1.0, bar_fill_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(display_duration)
	_active_tween.tween_property(_panel, "modulate:a", 0.0, fade_duration)
	
	
