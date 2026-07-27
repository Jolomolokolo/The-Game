extends CanvasLayer

@export var fade_duration := 0.4
@export var loading_screen_threshold := 0.3

var _color_rect : ColorRect
var _progress_bar : ProgressBar
var _loading_label : Label
var _is_transitioning := false

func _ready() -> void:
	layer = 128
	
	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_color_rect)
	
	_progress_bar = ProgressBar.new()
	_progress_bar.visible = false
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.
	_progress_bar.custom_minimum_size = Vector2(300, 20)
	_progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	_progress_bar.position -= Vector2(150, 0)
	_color_rect.add_child(_progress_bar)
	
	_loading_label = Label.new()
	_loading_label.visible = false
	_loading_label.text = "Loading..."
	_loading_label.set_anchors_preset(Control.PRESET_CENTER)
	_loading_label.position -= Vector2(30, 40)
	_color_rect.add_child(_loading_label)
	
func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_change_scene_async(path)
	
func _change_scene_async(path: String) -> void:
	await _fade(0.0, 1.0)
	
	var err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("Could NOT load scene...")
		_is_transitioning = false
		await _fade(1.0, 0.0)
		return
	
	var start_time = Time.get_ticks_msec()
	var showed_progress := false
	
	while true:
		var progress : Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		
		if elapsed > loading_screen_threshold and not showed_progress:
			showed_progress = true
			_progress_bar.visible = true
			_loading_label.visible = true
		
		if showed_progress and not progress.is_empty():
			_progress_bar.value = progress[0]
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Couln NOT Load Scene...")
			_is_transitioning = false
			await _fade(1.0, 0.0)
			return
			
		await get_tree().process_frame
	
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(new_scene)
	
	_progress_bar.visible = false
	_loading_label.visible = false
	
	await _fade(1.0, 0.0)
	_is_transitioning = false
	
func _fade(from_alpha: float, to_alpha: float) -> void:
	_color_rect.color.a = from_alpha
	var tween = create_tween()
	tween.tween_property(_color_rect, "color:a", to_alpha, fade_duration)
	await tween.finished
