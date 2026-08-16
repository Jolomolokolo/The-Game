extends Node3D

@export var shop_slot_scene: PackedScene
@export var available_items : Array[ShopItem] = []

var shop_open := false
var shop_just_opened := false
var shop_area_inside := false

@onready var shop_screen = $Control
@onready var tooltip_layer_open = $"CanvasLayer/Tooltip-Overlay"
@onready var grid_container = $Control/PanelContainer/VBoxContainer/ScrollContainer/GridContainer

signal shop_state_changed(is_open: bool)

func _ready():
	add_to_group("shop")
	shop_screen.visible = false
	tooltip_layer_open.visible = false
	_populate_shop()
	
func _populate_shop():
	for child in grid_container.get_children():
		child.queue_free()
	
	for item in available_items:
		var slot = shop_slot_scene.instantiate()
		grid_container.add_child(slot)
		slot.setup(item)
		slot.item_selected.connect(_on_item_selected)
	
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
		tooltip_layer_open.visible = true
	
func _on_shop_enter_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		shop_area_inside = false
		tooltip_layer_open.visible = false
		close_shop()
	
func open_shop():
	shop_open = true
	shop_just_opened = true
	GameState.set_state(GameState.State.UI)
	tooltip_layer_open.visible = false
	shop_screen.visible = true
	shop_state_changed.emit(true)
	
func close_shop():
	shop_screen.visible = false
	GameState.set_state(GameState.State.PLAYING)
	shop_open = false
	if shop_area_inside:
		tooltip_layer_open.visible = true
	shop_state_changed.emit(false)
	
func _on_item_selected(item: ShopItem):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if GameData.cash >= item.price:
		GameData.add_cash(-item.price)
		if player.has_method("add_buildable_object"):
			player.add_buildable_object(item.scene)
		print("Bought: ", item.item_name, " " , item.price)
	else:
		print("Not enough Cash")
	
