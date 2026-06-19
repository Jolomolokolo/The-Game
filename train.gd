extends Node3D

@export var max_speed := 20.0
@export var acceleration := 3.0
@export var brake_force := 6.0

var speed := 0.0
var player_inside := false
var player_ref : Node = null
var just_entered := false
var headlights_on := false
var gear := 0
var gear_names := {-1: "Reverse", 0: "Neutral", 1: "Forward"}

@onready var path_follow : PathFollow3D = get_parent()
@onready var train_camera = $DriveCamera
@onready var collision_body = $StaticBody3D

@onready var spot_front_right = $"SpotLight - front - right"
@onready var spot_front_left = $"SpotLight - front - left"
@onready var spot_back_right = $"SpotLight - back - right"
@onready var spot_back_left = $"SpotLight - back - left"
@onready var back_front_right = $"BackLight - front - right"
@onready var back_front_left = $"BackLight - front - left"
@onready var back_back_right = $"BackLight - back - right"
@onready var back_back_left = $"BackLight - back - left"

var headlights : Array
var brake_lights : Array

func _ready():
	add_to_group("car")
	train_camera.current = false
	spot_front_right.visible = false
	spot_front_left.visible = false
	spot_back_right.visible = false
	spot_back_left.visible = false
	back_front_right.visible = false
	back_front_left.visible = false
	back_back_right.visible = false
	back_back_left.visible = false
	
func _physics_process(delta):
	collision_body.global_position = global_position
	collision_body.global_rotation = global_rotation
	
	if not player_inside:
		_update_headlights()
		return
	
	if just_entered:
		just_entered = false
		return
		
	if Input.is_action_just_pressed("ui_interact"):
		exit_train()
		return
	
	if Input.is_action_just_pressed("train_up") and abs(speed) < 1.0:
		gear = min(gear + 1, 1)
	
	if Input.is_action_just_pressed("train_down") and abs(speed) < 1.0:
		gear = max(gear -1, -1)
	
	var forward = Input.get_action_strength("ui_up")
	var back = Input.get_action_strength("ui_down")
	
	if gear == 0:
		speed = move_toward(speed, 0.0, brake_force * delta)
	elif forward > 0:
		speed = move_toward(speed, max_speed * gear, acceleration * delta)
	elif back > 0:
		speed = move_toward(speed, 0.0, brake_force * delta)
	else:
		speed = move_toward(speed, 0.0, brake_force * 0.5 * delta)
	
	path_follow.progress += speed * delta
	
	_update_headlights()
	_update_brake_light(back > 0 and speed > 0)

func _update_headlights():
	if not player_inside:
		spot_front_right.visible = false
		spot_front_left.visible = false
		spot_back_right.visible = false
		spot_back_left.visible = false
		return
	
	spot_front_right.visible = gear == 1
	spot_front_left.visible = gear == 1
	
	spot_back_right.visible = gear == -1
	spot_back_left.visible = gear == -1
	
func _update_brake_light(is_braking: bool):
	var energy_normal := 3.0
	var energy_braking := 6.0
	
	if gear >= 0:
		back_back_right.visible = true
		back_back_left.visible = true
		back_front_right.visible = false
		back_front_left.visible = false
		back_back_right.light_energy = lerp(back_back_right.light_energy, energy_braking if is_braking else energy_normal, 0.1)
		back_back_left.light_energy = lerp(back_back_left.light_energy, energy_braking if is_braking else energy_normal, 0.1)
	else:
		back_front_right.visible = true
		back_front_left.visible = true
		back_back_right.visible = false
		back_back_left.visible = false
		back_front_right.light_energy = lerp(back_front_right.light_energy, energy_braking if is_braking else energy_normal, 0.1)
		back_front_left.light_energy = lerp(back_front_left.light_energy, energy_braking if is_braking else energy_normal, 0.1)
	
func enter_vehicle(player):
	player_ref = player
	player_inside = true
	just_entered = true
	player_ref.hide()
	player_ref.set_physics_process(false)
	player_ref.set_collision_layer_value(1, false)
	player_ref.set_collision_mask_value(1, false)
	train_camera.current = true
	
func exit_train():
	if player_ref == null:
		return
	player_inside = false
	speed = move_toward(speed, 0.0, brake_force)
	player_ref.global_position = global_position + global_transform.basis.x * 3.0
	player_ref.show()
	player_ref.set_physics_process(true)
	player_ref.notify_exit()
	var ref = player_ref
	player_ref = null
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(ref):
		ref.set_collision_layer_value(1, true)
		ref.set_collision_mask_value(1, true)
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		body.nearby_vehicle = self
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside:
		player_ref = null
		body.nearby_vehicle = null
