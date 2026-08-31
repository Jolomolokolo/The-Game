extends Control

@onready var preset1_button = $Preset1/Preset1
@onready var preset2_button = $Preset2/Preset2
@onready var preset3_button = $Preset3/Preset3
@onready var start_button = $StartButton

var selected_preset: GameData.Preset = GameData.Preset.NORMAL

var start := false

func _process(_delta: float) -> void:
	if start:
		start = false
		GameData.apply_preset(selected_preset)
		#GameState.set_state(GameState.State.PLAYING) BRINGT NIX
		SceneManager.change_scene("res://main.tscn")
	
func _on_preset_1_pressed() -> void:
	selected_preset = GameData.Preset.EASY
	preset2_button.release_focus()
	preset3_button.release_focus()
	
func _on_preset_2_pressed() -> void:
	selected_preset = GameData.Preset.NORMAL
	preset1_button.release_focus()
	preset3_button.release_focus()
	
func _on_preset_3_pressed() -> void:
	selected_preset = GameData.Preset.HARD
	preset1_button.release_focus()
	preset2_button.release_focus()

func _on_start_button_pressed() -> void:
	start = true
	
func _on_return_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/StartPage.tscn")
	
func _on_customize_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/custom_preset.tscn")
