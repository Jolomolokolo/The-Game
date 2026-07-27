extends Control

var parent : Node = null

func _ready() -> void:
	parent = get_parent()

func _on_return_button_pressed() -> void:
	parent.close_pc_screen()
