extends Node3D

@export var max_speed := 20.0
@export var acceleration := 3.0
@export var brake_force := 6.0

var speed := 0.0
var player_inside := false
var player_ref : Node = null
var just_entered := false

@onready var path_follow : PathFollow3D = get_parent()
@onready var train_camera = $DriveCamera

func _ready():
	add_to_group("car")
	train_camera.current = false
	
func _physics_process(delta):
	if not player_inside:
		return
	
	if just_entered:
		just_entered = false
		return
		
	if Input.is_action_just_pressed("ui_interact"):
		exit_train()
		return
	
	var forward = Input.get_action_strength("ui_up")
	var back = Input.get_action_strength("ui_down")
	
	if forward > 0:
		speed = move_toward(speed, max_speed, acceleration * delta)
	elif back > 0:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, brake_force * delta)
		else:
			speed = move_toward(speed, -max_speed * 0.3, acceleration * delta)
		
	else:
		speed = move_toward(speed, 0.0, brake_force * 3.0 * delta)
	
	path_follow.progress += speed * delta
	
	_update_brake_light(back > 0 and speed > 0)
	
func _update_brake_light(braking: bool):
	pass
	
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
