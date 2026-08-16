extends Node3D

@onready var tooltip_layer_open = $"CanvasLayer/Tooltip - Overlay"
@onready var pc_screen = $PCScreen

var pc_screen_open := false
var pc_screen_just_opened := false
var pc_screen_area_inside := false

func _ready() -> void:
	add_to_group("pc")
	tooltip_layer_open.visible = false
	pc_screen.visible = false
	
func _process(_delta: float) -> void:
	if pc_screen_just_opened:
		pc_screen_just_opened = false
		return
	
	if pc_screen_area_inside and Input.is_action_just_pressed("e") and not pc_screen_open:
		open_pc_screen()
	
func open_pc_screen():
	pc_screen_open = true
	tooltip_layer_open.visible = false
	pc_screen.visible = true
	GameState.set_state(GameState.State.UI)
	
func close_pc_screen():
	GameState.set_state(GameState.State.PLAYING)
	pc_screen_open = false
	if pc_screen_area_inside:
		tooltip_layer_open.visible = true
	pc_screen.visible = false
	
func _on_shop_enter_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		pc_screen_area_inside = true
		tooltip_layer_open.visible = true
	
func _on_shop_enter_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		pc_screen_area_inside = false
		tooltip_layer_open.visible = false
