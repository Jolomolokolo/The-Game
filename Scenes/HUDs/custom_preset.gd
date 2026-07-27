extends Control

@onready var cash_box = $Cash
@onready var health_box = $Health

var start := false
var cash := 250
var health := 100

func _ready() -> void:
	cash_box.value = cash

func _process(_delta: float) -> void:
	if start:
		cash = cash_box.value
		health = health_box.value
		GameData.apply_custom_preset(cash, health)
		SceneManager.change_scene("res://main.tscn")
		start = false
	
func _on_return_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/GameCreation.tscn")
	
func _on_customize_button_pressed() -> void:
	start = true
