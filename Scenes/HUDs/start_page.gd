extends Control

@onready var version_label = $VersionLabel
@onready var start_button : Label = $StartButton/Label

@export var version := ""

func _ready() -> void:
	version_label.text = "Version: " + version
	_refresh_start_button()

func _refresh_start_button() -> void:
	if SaveManager.has_any_save():
		var latest_slot = SaveManager.get_most_recent_slot()
		var info := SaveManager.get_save_info(latest_slot)
		start_button.text = "Continue: %s" % info.get("name", "Save %d" % latest_slot)
	else:
		start_button.text = "Start New Game"
	
func _on_start_button_pressed() -> void:
	if SaveManager.has_any_save():
		var latest_slot = SaveManager.get_most_recent_slot()
		SaveManager.request_load_on_scene_ready(latest_slot, true)
		GameState.set_state(GameState.State.PLAYING)
		SceneManager.change_scene("res://main.tscn")
	else:
		SceneManager.change_scene("res://Scenes/HUDs/GameCreation.tscn")
	
func _on_target_scene_ready(slot: int):
	SaveManager.load_game(slot)
	
func _on_save_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/SaveSelectPage.tscn")
	
func _on_settings_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/Settings.tscn")
	
