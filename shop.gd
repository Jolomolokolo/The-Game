extends Node3D

var shop_open := false
var shop_just_opened := false
var shop_area_inside := false

@onready var shop_screen = $Control


func _ready():
	shop_screen.visible = false
	
func _process(_delta: float):
	if shop_just_opened:
		shop_just_opened = false
		return
	
	if shop_area_inside == true and Input.is_action_just_pressed("e") and not shop_open:
		open_shop()
	
	if shop_area_inside and Input.is_action_just_pressed("e") and not shop_just_opened and shop_open:
		close_shop()
	
func _on_shop_enter_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		shop_area_inside = true
	
func _on_shop_enter_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		shop_area_inside = false
		close_shop()
	
func open_shop():
	shop_open = true
	shop_just_opened = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	shop_screen.visible = true
	
func close_shop():
	shop_screen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shop_open = false

# After Button Press, MOUSE_MODE_VISIBLE machen... eventuell per Inspektor sogar möglich
# Buttons im GridContainer gleichmäßig verteilen -> Rechere, wie man GridContainer richtig einsetzt
