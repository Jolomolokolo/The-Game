extends Control

func _on_start_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/GameCreation.tscn")
	
func _on_settings_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/Settings.tscn")
