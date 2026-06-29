extends Node3D

@export var max_speed := 20.0
@export var acceleration := 3.0
@export var brake_force := 6.0

var speed := 0.0
var player_inside := false
var player_ref : Node = null
var just_entered := false
var gear := 0
var current_camera = 1

var current_track : Path3D = null
var current_path_follow : PathFollow3D = null
var current_junction = null
var current_track_name := ""
var _rail_network : Node = null

var current_progress : float = 0.0

@onready var train_camera = $DriveCamera
@onready var train_camera_backward = $DriveCameraBackward
@onready var collision_body = $AnimatableBody3D
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

func _ready():
	add_to_group("train")
	$AnimatableBody3D.add_to_group("train_collision")
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
	
	_rail_network = _find_rail_network()
	
	_init_track_from_parent()
	
func _init_track_from_parent() -> void:
	var parent = get_parent()
	if parent is PathFollow3D:
		current_path_follow = parent
		var grandparent = parent.get_parent()
		if grandparent is Path3D:
			current_track = grandparent
			current_track_name = grandparent.name
			current_progress = current_path_follow.progress
			print("Train started on Track: %s" % current_track_name)
	
	
func _physics_process(delta):
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
		gear = max(gear - 1, -1)
	
	if current_junction != null:
		if Input.is_action_just_pressed("ui_left"):
			current_junction.switch_left(current_track_name)
		if Input.is_action_just_pressed("ui_right"):
			current_junction.switch_right(current_track_name)
	
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
	
	current_progress += speed * delta
	
	if current_path_follow:
		current_path_follow.progress = current_progress
	
	_check_track_bounds()
	
	_update_camera()
	_update_headlights()
	_update_brake_light(back > 0 and speed > 0)
	
func _check_track_bounds() -> void:
	if current_track == null or current_path_follow == null:
		return
	
	var track_length = current_track.curve.get_baked_length()
	
	if current_progress >= track_length:
		if _rail_network:
			var next = _rail_network.get_next_track(current_track, 1)
			if next:
				var overshoot = current_progress - track_length
				_switch_to_track(next, overshoot, true)
			else:
				current_progress = track_length
				current_path_follow.progress = track_length
				speed = 0.0
	elif current_progress <= 0.0:
		if _rail_network:
			var prev = _rail_network.get_next_track(current_track, -1)
			if prev:
				var prev_length = prev.curve.get_baked_lenght()
				var overshoot = abs(current_progress)
				_switch_to_track(prev, prev_length - overshoot, false)
			else:
				current_progress = 0.0
				current_path_follow.progress = 0.0
				speed = 0.0
	
func _switch_to_track(new_track: Path3D, start_progress: float, forwards: bool) -> void:
	print("Train switches to Track: %s (at %.1f)" % [new_track.name, start_progress])
	
	var new_path_follow : PathFollow3D = null
	for child in new_track.get_children():
		if child is PathFollow3D:
			new_path_follow = child
			break
	
	if new_path_follow == null:
		push_error("Train: No PathFollow3D in Track found: %s" % new_track.name)
		return
	
	var saved_transform = global_transform
	current_path_follow.remove_child(self)
	new_path_follow.add_child(self)
	global_transform = saved_transform
	
	current_track = new_track
	current_track_name = new_track.name
	current_path_follow = new_path_follow
	current_progress = clampf(start_progress, 0.0, new_track.curve.get_baked_length())
	current_path_follow.progress = current_progress
	
func notify_junction_enter(junction) -> void:
	current_junction = junction
	print("Train: Junction in reach: %s" % junction.name)
	
func notify_junction_exit(junction) -> void:
	if current_junction == junction:
		current_junction = null
	
func _find_rail_network() -> Node:
	var node = get_parent()
	while node:
		if node.has_method("get_next_track"):
			return node
		node = node.get_parent()
	return null
	
func _update_camera():
	if gear >= 0:
		train_camera.current = true
		train_camera_backward.current = false
	else:
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
		train_camera_backward.current = true
	tooltip_layer.visible = true
	tooltip_layer_enter.visible = false
	
func exit_train():
	if player_ref == null:
		return
	tooltip_layer.visible = false
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
		tooltip_layer_enter.visible = true
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside:
		player_ref = null
		body.nearby_vehicle = null
		tooltip_layer_enter.visible = false
	
