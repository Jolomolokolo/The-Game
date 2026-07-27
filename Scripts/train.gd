extends Node3D

# COMPLETE TRAIN OVERALL, WITH REAL PHYSICS AND WITH VEHICLEBODY

@export var max_speed := 20.0
@export var acceleration := 3.0
@export var brake_force := 6.0
@export var weight := 20.0
@export var tractive_force := 60.0

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

var _nearby_carriages : Array = []
var _nearby_carriage : Node = null
var _couple_area_front : Area3D = null
var _couple_area_back : Area3D = null
var _coupled_carriages : Array[Node] = []
@export var couple_distance := 4.0

@onready var train_camera = $DriveCamera
@onready var train_camera_backward = $DriveCameraBackward
@onready var train_camera_top = $DriveCameraTop
@onready var train_camera_backward_top = $DriveCameraBackwardTop
@onready var collision_body = $AnimatableBody3D
@onready var tooltip_layer = $"CanvasLayer/Tooltip-Train"
@onready var tooltip_layer_enter = $"CanvasLayer/Tooltip-Overlay"
@onready var switch_hud = $CanvasLayer/Rail_Switch_HUD
@onready var map_hud = $CanvasLayer/Map_HUD
@onready var carriage_hud = $CanvasLayer/Carriage_HUD
@onready var couple_menu = $CanvasLayer/CoupleMenu

@onready var spot_front_right = $"SpotLight - front - right"
@onready var spot_front_left = $"SpotLight - front - left"
@onready var spot_back_right = $"SpotLight - back - right"
@onready var spot_back_left = $"SpotLight - back - left"
@onready var back_front_right = $"BackLight - front - right"
@onready var back_front_left = $"BackLight - front - left"
@onready var back_back_right = $"BackLight - back - right"
@onready var back_back_left = $"BackLight - back - left"

@onready var front_front_left = $"FrontLight - front - left"
@onready var front_front_right = $"FrontLight - front - right"
@onready var front_back_left = $"FrontLight - back - left"
@onready var front_back_right = $"FrontLight - back - right"

var off_material : StandardMaterial3D
var mat_yellow : StandardMaterial3D

func _ready():
	add_to_group("train")
	$AnimatableBody3D.add_to_group("train")
	$AnimatableBody3D.add_to_group("train_collision")
	train_camera.current = false
	train_camera_backward.current = false
	train_camera_top.current = false
	train_camera_backward_top.current = false
	tooltip_layer.visible = false
	tooltip_layer_enter.visible = false
	switch_hud.visible = false
	map_hud.visible = false
	spot_front_right.visible = false
	spot_front_left.visible = false
	spot_back_right.visible = false
	spot_back_left.visible = false
	back_front_right.visible = false
	back_front_left.visible = false
	back_back_right.visible = false
	back_back_left.visible = false
	_build_materials()
	
	_rail_network = _find_rail_network()
	
	_init_track_from_parent()
	
	_couple_area_front = get_node_or_null("CoupleAreaFront")
	_couple_area_back = get_node_or_null("CoupleAreaBack")
	
	var map = get_node_or_null("CanvasLayer/Map_HUD")
	if map and map.has_method("initialize"):
		map.initialize(_rail_network, self)
	
	carriage_hud.visible = false
	if carriage_hud and carriage_hud.has_method("initialize"):
		carriage_hud.initialize(self)
	
	couple_menu.visible = false
	if couple_menu.has_method("initialize"):
		couple_menu.initialize(self)
	
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
	
	if Input.is_action_just_pressed("camera_1"):
		current_camera = 1
		_update_camera()
	if Input.is_action_just_pressed("camera_2"):
		current_camera = 2
		_update_camera()
	
	if Input.is_action_just_pressed("ui_interact"):
		exit_train()
		return
	
	if Input.is_action_just_pressed("train_up") and abs(speed) < 1.0:
		gear = min(gear + 1, 1)
	if Input.is_action_just_pressed("train_down") and abs(speed) < 1.0:
		gear = max(gear - 1, -1)
	
	if current_junction != null:
		if Input.is_action_just_pressed("ui_left"):
			current_junction.switch_right(current_track_name)
			_update_switch_hud()
		if Input.is_action_just_pressed("ui_right"):
			current_junction.switch_left(current_track_name)
			_update_switch_hud()
	
	if Input.is_action_just_pressed("train_couple"):
		_try_couple_or_decouple()
	
	_check_nearby_carriage()
	
	var forward = Input.get_action_strength("ui_up")
	var back = Input.get_action_strength("ui_down")
	
	var total_weight = _get_total_weight()
	var total_force = _get_total_tractive_force()
	
	var effective_acceleration = acceleration * (total_force / total_weight)
	var effective_brake = brake_force * (total_force / total_weight)
	
	if gear == 0:
		speed = move_toward(speed, 0.0, effective_brake * delta)
	elif forward > 0:
		speed = move_toward(speed, max_speed * gear, effective_acceleration * delta)
	elif back > 0:
		speed = move_toward(speed, 0.0, effective_brake * delta)
	else:
		speed = move_toward(speed, 0.0, effective_brake * 0.5 * delta)
	
	current_progress += speed * delta
	
	_check_carriage_collision()
	_check_coupled_carriage_collision()
	
	if current_path_follow:
		current_path_follow.progress = current_progress
	
	_check_track_bounds()
	
	_update_camera()
	_update_headlights()
	_update_brake_light(back > 0 and speed > 0)
	
	if player_inside:
		_update_next_junction()
	
	_update_carriages()
	
func _check_track_bounds():
	if current_track == null or current_path_follow == null:
		return
	
	var track_length = current_track.curve.get_baked_length()
	
	if current_progress >= track_length:
		if _rail_network:
			var next = _rail_network.get_next_track(current_track, 1)
			if next:
				var overshoot = current_progress - track_length
				_switch_to_track(next, overshoot)
			else:
				current_progress = track_length
				current_path_follow.progress = track_length
				speed = 0.0
	elif current_progress <= 0.0:
		if _rail_network:
			var prev = _rail_network.get_next_track(current_track, -1)
			if prev:
				var prev_length = prev.curve.get_baked_length()
				var overshoot = abs(current_progress)
				_switch_to_track(prev, prev_length - overshoot)
			else:
				current_progress = 0.0
				current_path_follow.progress = 0.0
				speed = 0.0
	
func _switch_to_track(new_track: Path3D, start_progress: float) -> void:
	var new_path_follow : PathFollow3D = null
	for child in new_track.get_children():
		if child is PathFollow3D:
			new_path_follow = child
			break
	
	if new_path_follow == null:
		push_error("Train: No PathFollow3D in Track found: %s" % new_track.name)
		return
	
	current_path_follow.remove_child(self)
	new_path_follow.add_child(self)
	
	transform = Transform3D.IDENTITY
	
	current_track = new_track
	current_track_name = new_track.name
	current_path_follow = new_path_follow
	current_progress = clampf(start_progress, 0.0, new_track.curve.get_baked_length())
	current_path_follow.progress = current_progress
	
func notify_junction_enter(junction):
	current_junction = junction
	print("Train: Junction in reach: %s" % junction.name)
	_update_switch_hud()
	
func notify_junction_exit(junction):
	if current_junction == junction:
		current_junction = null
		if switch_hud:
			switch_hud.visible = false
	
func _find_rail_network() -> Node:
	var node = get_parent()
	while node:
		if node.has_method("get_next_track"):
			return node
		node = node.get_parent()
	return null
	
func _update_camera():
	train_camera.current = false
	train_camera_backward.current = false
	train_camera_top.current = false
	train_camera_backward_top.current = false
	
	if current_camera == 1:
		train_camera.current = gear >= 0
		train_camera_backward.current = gear < 0
	elif current_camera == 2:
		train_camera_top.current = gear >= 0
		train_camera_backward_top.current = gear < 0
	
func _update_headlights():
	if not player_inside:
		spot_front_right.visible = false
		spot_front_left.visible = false
		spot_back_right.visible = false
		spot_back_left.visible = false
		front_front_left.material_override = off_material
		front_front_right.material_override = off_material
		front_back_left.material_override = off_material
		front_back_right.material_override = off_material
		return
	spot_front_right.visible = gear == 1
	spot_front_left.visible = gear == 1
	spot_back_right.visible = gear == -1
	spot_back_left.visible = gear == -1
	
	if gear == 1:
		front_front_left.material_override = mat_yellow
		front_front_right.material_override = mat_yellow
		front_back_left.material_override = off_material
		front_back_right.material_override = off_material
	if gear == -1:
		front_front_left.material_override = off_material
		front_front_right.material_override = off_material
		front_back_left.material_override = mat_yellow
		front_back_right.material_override = mat_yellow
	
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
	map_hud.visible = true
	carriage_hud.visible = true
	couple_menu.visible = false
	_update_switch_hud()
	
func exit_train():
	if player_ref == null:
		return
	tooltip_layer.visible = false
	player_inside = false
	speed = move_toward(speed, 0.0, brake_force)
	player_ref.global_position = global_position + global_transform.basis.x * 3.0
	player_ref.show()
	switch_hud.visible = false
	map_hud.visible = false
	carriage_hud.visible = false
	couple_menu.hide_menu()
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
	
func _update_switch_hud():
	if not switch_hud:
		return
	if not player_inside:
		switch_hud.visible = false
		return
	if current_junction == null or gear == -1:
		switch_hud.text = "No Junction"
		switch_hud.visible = true
		return
	
	var dir = current_junction.current_direction
	var dir_text = "MAIN\n                         <-" if dir == "main" else "BRANCH\n                         ->"
	switch_hud.text = "%s: %s\n[A] Main              [D] Branch" % [current_junction.name, dir_text]
	switch_hud.visible = true
	
func _update_next_junction():
	if _rail_network == null:
		return
	var next_sw = _rail_network.get_next_switch_for(current_track)
	if next_sw != current_junction:
		current_junction = next_sw
	_update_switch_hud()
	
func _check_nearby_carriage() -> void:
	if not player_inside:
		_nearby_carriages.clear()
		_nearby_carriage = null
		return
	
	_nearby_carriages.clear()
	
	var areas_to_eheck : Array = []
	
	if _couple_area_front:
		areas_to_eheck.append(_couple_area_front)
	if _couple_area_back:
		areas_to_eheck.append(_couple_area_back)
	
	for coupled in _coupled_carriages:
		if not is_instance_valid(coupled):
			continue
		var cf = coupled.get_node_or_null("CoupleAreaFront")
		var cb = coupled.get_node_or_null("CoupleAreaBack")
		if cf: areas_to_eheck.append(cf)
		if cb: areas_to_eheck.append(cb)
	
	for area in areas_to_eheck:
		for body in area.get_overlapping_areas():
			var target : Node = null
			if body.is_in_group("train_carriage"):
				target = body
			elif body.get_parent() and body.get_parent().is_in_group("train_carriage"):
				target = body.get_parent()
				
			if target and not _coupled_carriages.has(target) and not _nearby_carriages.has(target):
				_nearby_carriages.append(target)
	
	_nearby_carriage= _nearby_carriages[0] if _nearby_carriages.size() > 0 else null
	print("Nearby: %d" % _nearby_carriages.size())
	
func _try_couple_or_decouple():
	if _nearby_carriages.size() > 0 or _coupled_carriages.size() > 0:
		if couple_menu.visible:
			couple_menu.hide_menu()
		else:
			couple_menu.show_menu()
	
func _couple_carriage(carriage: Node):
	_coupled_carriages.append(carriage)
	carriage.couple()
	print("Train: Carriage coupled: %s (all: %d)" % [carriage.name, _coupled_carriages.size()])
	
func _decouple_last():
	if _coupled_carriages.is_empty():
		return
	var last = _coupled_carriages.back()
	_coupled_carriages.pop_back()
	if is_instance_valid(last):
		last.decouple()
	print("Train: Last carriage decoupled. Remaining: %d" % _coupled_carriages.size())
	
func _update_carriages() -> void:
	if _coupled_carriages.is_empty():
		return
	
	var prev_progress = current_progress
	var prev_track = current_track
	var prev_follow = current_path_follow
	
	for i in range(_coupled_carriages.size()):
		var carriage = _coupled_carriages[i]
		if not is_instance_valid(carriage):
			continue
		carriage.leader_is_train = (i == 0)
		carriage.update_coupled_position(prev_progress, prev_track, prev_follow, speed)
		prev_progress = carriage.current_progress
		prev_track = carriage.current_track
		prev_follow = carriage.current_path_follow
	
func _check_carriage_collision():
	for carriage in get_tree().get_nodes_in_group("train_carriage"):
		if not is_instance_valid(carriage):
			continue
		if _coupled_carriages.has(carriage):
			continue
		if not carriage.current_track or not current_track:
			continue
		if carriage.current_track.name != current_track.name:
			continue
		
		var dist = current_progress - carriage.current_progress
		var abs_dist = abs(dist)
		var min_dist = 7.6
		
		if abs_dist >= min_dist:
			continue
		
		var push_dir = sign(dist)
		if push_dir == 0:
			push_dir = 1
		
		var moving_toward = sign(speed) != push_dir and speed != 0.0
		
		if moving_toward:
			if abs(carriage.velocity) < 1.0:
				carriage.velocity = speed * 0.7
			speed = move_toward(speed, 0.0, abs(speed) * 0.02)
			if abs(speed) < 0.3:
				speed = 0.0
		
		if abs(carriage.velocity) < abs(speed):
			current_progress = carriage.current_progress + min_dist * push_dir
			current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length())
			if current_path_follow:
				current_path_follow.progress = current_progress
		
		return
	
func _check_coupled_carriage_collision() -> void:
	if _coupled_carriages.is_empty():
		return
	
	var first = _coupled_carriages[0]
	if not is_instance_valid(first):
		return
	if not first.current_track or not current_track:
		return
	if first.current_track.name != current_track.name:
		return
	
	var dist = current_progress - first.current_progress
	var abs_dist = abs(dist)
	var min_dist = 7.6
	
	if abs_dist >= min_dist:
		return
	
	var push_dir = sign(dist)
	if push_dir == 0:
		push_dir = 1
	
	var moving_toward = (speed > 0 and push_dir > 0) or (speed < 0 and push_dir < 0)
	
	if not moving_toward:
		return
	
	speed = 0.0
	current_progress = first.current_progress + min_dist * push_dir
	current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length())
	if current_path_follow:
		current_path_follow.progress = current_progress
	
func _get_total_weight() -> float:
	var total = weight
	for carriage in _coupled_carriages:
		if is_instance_valid(carriage) and carriage.has_method("get_coupled_position"):
			total += carriage.get("weight") if carriage.get("weight") != null else 10.0
	return total
	
func _get_total_tractive_force() -> float:
	var total = tractive_force
	for carriage in _coupled_carriages:
		if is_instance_valid(carriage) and carriage.get("tractive_force") != null:
			total += carriage.get("tractive_force")
	return total
	
func _build_materials():
	off_material = StandardMaterial3D.new()
	off_material.albedo_color = Color(1, 0.6, 0)
	mat_yellow = _make_glow_material(Color(1, 0.6, 0))
	
func _make_glow_material(color: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	return mat
	
func get_nearby_carriages() -> Array:
	return _nearby_carriages
	
func get_coupled_carriages() -> Array:
	return _coupled_carriages
