extends Control

@onready var desktop = $PanelContainer/Desktop
@onready var bank_app = $PanelContainer/BankApp
@onready var job_app = $PanelContainer/JobApp

var parent : Node = null

func _ready() -> void:
	parent = get_parent()

func _on_return_button_pressed() -> void:
	parent.close_pc_screen()

func _on_bank_app_pressed() -> void:
	desktop.visible = false
	job_app.visible = false
	bank_app.visible = true
	
func _on_job_app_pressed() -> void:
	desktop.visible = false
	bank_app.visible = false
	job_app.visible = true
	
func _on_bank_app_return_desktop() -> void:
	bank_app.visible = false
	job_app.visible = false
	desktop.visible = true
	
func _on_job_app__return_desktop() -> void:
	job_app.visible = false
	bank_app.visible = false
	desktop.visible = true
	
