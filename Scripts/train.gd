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
#var gear_names := {-1: "Reverse", 0: "Neutral", 1: "Forward"}
var current_camera = 1

@onready var path_follow : PathFollow3D = get_parent()
@onready var train_camera = $DriveCamera
@onready var train_camera_backward = $DriveCameraBackward
@onready var collision_body = $StaticBody3D
@onready var tooltip_layer = $"CanvasLayer/Tooltip-Train"
@onready var tooltip_layer_enter = $"CanvasLayer/Tooltip-Overlay"

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

var current_track_name : String = "Track_A"
var network : Node = null
var nearest_junction : Node = null

func _ready():
	add_to_group("train")
	train_camera.current = false
	train_camera_backward.current = false
	tooltip_layer.visible = false
	tooltip_layer_enter.visible = false
	spot_front_right.visible = false
	spot_front_left.visible = false
	spot_back_right.visible = false
	spot_back_left.visible = false
	back_front_right.visible = false
	back_front_left.visible = false
	back_back_right.visible = false
	back_back_left.visible = false
	
	await get_tree().process_frame
	network = get_tree().get_first_node_in_group("rail_network")
	
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
	
	_update_camera()
	
	_update_headlights()
	_update_brake_light(back > 0 and speed > 0)
	
	_check_nearest_junction()
	
	if nearest_junction != null:
		if Input.is_action_just_pressed("ui_left"):
			nearest_junction.switch_left(current_track_name)
		if Input.is_action_just_pressed("ui_right"):
			nearest_junction.switch_right(current_track_name)
	
	_check_track_end()
	
func _check_nearest_junction():
	nearest_junction = null
	for junction in get_tree().get_first_node_in_group("rail_switch"):
		if junction.is_near(path_follow.progress, current_track_name):
			nearest_junction = junction
			return
	
func _check_track_end():
	if network == null:
		return
	var track_length = path_follow.get_parent().curve.get_baked_length()
	if path_follow.progress >= track_length - 1.0:
		if nearest_junction != null:
			var next_name = nearest_junction.get_next_track(current_track_name)
			if next_name != "":
				_switch_to_track(next_name)
	
func _switch_to_track(new_track_name: String):
	var new_path = network.get_track(new_track_name)
	if new_path == null:
		return
	
	var new_follow = PathFollow3D.new()
	new_follow.rotation_mode = PathFollow3D.ROTATION_XYZ
	new_follow.loop = false
	new_path.add_children(new_follow)
	
	var old_follow = path_follow
	reparent(new_follow)
	path_follow = new_follow
	path_follow.progress = 0.0
	
	old_follow.queue_free()
	current_track_name = new_track_name
	print("Switched to: ", current_track_name)
	
func _update_camera():
	if gear == 0:
		train_camera.current = true
		train_camera_backward.current = false
	elif gear == 1:
		train_camera.current = true
		train_camera_backward.current = false
	elif gear == -1:
		train_camera.current = false
		train_camera_backward.current = true

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
	if current_camera == 1:
		train_camera.current = true
	elif current_camera == 2:
		train_camera_backward = true
	tooltip_layer.visible = true
	tooltip_layer_enter.visible = false
	
func exit_train():
	if player_ref == null:
		return
	tooltip_layer.visible = false
	player_inside = false
	tooltip_layer.visible = false
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
		tooltip_layer_enter.visible = true
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside:
		player_ref = null
		body.nearby_vehicle = null
		tooltip_layer_enter.visible = false
