extends RigidBody3D
class_name Train

@export var entity_id: String = ""
@export var max_speed := 20.0
@export var acceleration := 3.0
@export var brake_force := 6.0
@export var weight_tons := 20.0
@export var tractive_force := 60.0

@export var spring_strenght := 800.0
@export var spring_damping := 120.0
@export var derail_distance := 5.0
@export var derail_speed_curve := 120.0

var speed := 0.0
@export var player_inside := false # Player wieder automatisch in den Zug setzen
var player_ref : Node3D = null
var just_entered := false
@export var gear := 0
@export var current_camera := 1
@export var is_derailed := false

var current_track : Path3D = null
var current_path_follow : PathFollow3D = null
@export var current_progress : float = 0.0
@export var current_track_name := ""
var _rail_network : Node = null
var current_junction = null # @export ???

@export var _coupled_carriages : Array[Node] = []
var _nearby_carriages : Array = []
var _nearby_carriage : Node = null
@export var couple_distance := 5.0

var _anchor : Node3D = null
@export var _derail_grace_time := 2.0
@export var _time_alive := 0.0

@onready var train_camera = $DriveCamera
@onready var train_camera_backward = $DriveCameraBackward
@onready var train_camera_top = $DriveCameraTop
@onready var train_camera_backward_top = $DriveCameraBackwardTop
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

func _ready() -> void:
	add_to_group("train")
	
	gravity_scale = 0.3
	mass = weight_tons
	
	train_camera.current = false
	train_camera_backward.current = false
	train_camera_top.current = false
	train_camera_backward_top.current = false
	tooltip_layer.visible = false
	tooltip_layer_enter.visible = false
	switch_hud.visible = false
	map_hud.visible = false
	
	_rail_network = _find_rail_network()
	_init_track_from_parent()
	_create_anchor()
	
	var map = get_node_or_null("CanvasLayer/Map_HUD")
	if map and map.has_method("initialize"):
		map.initialize(_rail_network, self)
	carriage_hud.visible = false
	if carriage_hud and carriage_hud.has_method("initialize"):
		carriage_hud.initialize(self)
	couple_menu.visible = false
	if couple_menu and couple_menu.has_method("initialize"):
		couple_menu.initialize(self)
	
	_build_materials()
	
func _init_track_from_parent() -> void:
	_rail_network = _find_rail_network()
	print("_rail_network gefunden: ", _rail_network)
	if _rail_network:
		print("_rail_network Pfad: ", _rail_network.get_path())
		print("_rail_network Kinder: ", _rail_network.get_children())
	if not _rail_network:
		return
	
	for child in _rail_network.get_children():
		if child is Path3D:
			current_track = child
			current_track_name = child.name
			for sub in child.get_children():
				if sub is PathFollow3D:
					current_path_follow = sub
					current_progress = 0.0
					break
			break
	
	#
	print("current_track: ", current_track)
	print("current_path_follow: ", current_path_follow)
	#
	
	print("Train started on Track: %s" % current_track_name)
	
func _create_anchor() -> void:
	# Maybe Progress ?
	_anchor = Marker3D.new()
	_anchor.name = "TrainAnchor"
	if current_path_follow:
		current_path_follow.add_child(_anchor)
	if _anchor:
		global_position = _anchor.global_position
	
func _physics_process(delta: float) -> void:
	if is_derailed:
		_update_derailed(delta)
		return
	
	_time_alive += delta
	
	if _time_alive > _derail_grace_time:
		_check_derailment()
	
	if current_path_follow:
		current_path_follow.progress = current_progress
	
	if _anchor and not is_derailed:
		_apply_spring_force(delta)
	
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
	var back    = Input.get_action_strength("ui_down")
	
	var total_weight = _get_total_weight()
	var total_force  = _get_total_tractive_force()
	var eff_acc   = acceleration * (total_force / total_weight)
	var eff_brake = brake_force  * (total_force / total_weight)
	
	if gear == 0:
		speed = move_toward(speed, 0.0, eff_brake * delta)
	elif forward > 0:
		speed = move_toward(speed, max_speed * gear, eff_acc * delta)
	elif back > 0:
		speed = move_toward(speed, 0.0, eff_brake * delta)
	else:
		speed = move_toward(speed, 0.0, eff_brake * 0.5 * delta)
	
	current_progress += speed * delta
	_check_track_bounds()
	
	_update_camera()
	_update_headlights()
	_update_brake_light(back > 0 and speed > 0)
	
	if player_inside:
		_update_next_junction()
	
	_update_carriages()
	
func _apply_spring_force(delta: float) -> void:
	if not _anchor:
		return
	
	var target_pos = _anchor.global_position
	var current_pos = global_position
	var diff = target_pos - current_pos
	var dist = diff.length()
	
	var spring_force = diff.normalized() * dist * spring_strenght
	var damping_force = -linear_velocity * spring_damping
	
	apply_central_force(spring_force + damping_force)
	
	var track_forward = - _anchor.global_transform.basis.z
	if track_forward.length() > 0.01:
		var target_basis = Basis.looking_at(track_forward, Vector3.UP)
		var current_quat = Quaternion(global_basis.orthonormalized())
		var target_quat = Quaternion(target_basis)
		var new_quat = current_quat.slerp(target_quat, delta * 10.0)
		global_basis = Basis(new_quat)
		angular_velocity = Vector3.ZERO
	
func _check_derailment() -> void:
	if not _anchor:
		return
	
	var dist_to_track = global_position.distance_to(_anchor.global_position)
	
	if dist_to_track > derail_distance:
		_derail()
		return
	
	if current_track and current_path_follow:
		var curve_speed = abs(speed)
		var lenght = current_track.curve.get_baked_length()
		if lenght > 0:
			var ahead = clampf(current_progress + 2.0, 0.0, lenght)
			var behind = clampf(current_progress - 2.0, 0.0, lenght)
			var pos_ahead = current_track.to_global(current_track.curve.sample_baked(ahead))
			var pos_behind = current_track.to_global(current_track.curve.sample_baked(behind))
			var track_dir = (pos_ahead - pos_behind).normalized()
			var train_dir = - global_transform.basis.z
			var angle_diff = track_dir.angle_to(train_dir)
			
			if curve_speed > derail_speed_curve * (1.0 - angle_diff):
				_derail()
	
func _derail():
	if is_derailed:
		return
	
	is_derailed = true
	speed = 0.0
	gravity_scale = 1.0
	_anchor = null
	print("Train DERAILED")
	
func _update_derailed(_delta: float) -> void:
	_update_headlights()
	
	if player_inside and Input.is_action_just_pressed("e") and not just_entered:
		just_entered = false
		exit_train()
	
func _check_track_bounds() -> void:
	if current_track == null or current_path_follow == null:
		return
	
	var track_length = current_track.curve.get_baked_length()
	
	if current_progress >= track_length:
		if _rail_network:
			var next = _rail_network.get_next_track(current_track, 1)
			if next:
				_switch_to_track(next, current_progress - track_length)
			else:
				current_progress = track_length
				speed = 0.0
	elif current_progress <= 0.0:
		if _rail_network:
			var prev = _rail_network.get_next_track(current_track, -1)
			if prev:
				_switch_to_track(prev, prev.curve.get_baked_length() + current_progress)
			else:
				current_progress = 0.0
				speed = 0.0
	
func _switch_to_track(new_track: Path3D, start_progress: float) -> void:
	var new_path_follow : PathFollow3D = null
	for child in new_track.get_children():
		if child is PathFollow3D:
			new_path_follow = child
			break
	
	if not new_path_follow:
		push_error("Train: No PathFollow3D in: %s" % new_track.name)
		return
	
	if _anchor and current_path_follow:
		current_path_follow.remove_child(_anchor)
		new_path_follow.add_child(_anchor)
	
	current_track = new_track
	current_track_name = new_track.name
	current_path_follow = new_path_follow
	current_progress = clampf(start_progress, 0.0, new_track.curve.get_baked_length())
	
func _check_nearby_carriage() -> void:
	if not player_inside:
		_nearby_carriages.clear()
		_nearby_carriage = null
		return
	
	_nearby_carriages.clear()
	
	var couple_area_front = get_node_or_null("CoupleAreaFront")
	var couple_area_back  = get_node_or_null("CoupleAreaBack")
	
	var areas_to_check : Array = []
	if couple_area_front: areas_to_check.append(couple_area_front)
	if couple_area_back:  areas_to_check.append(couple_area_back)
	
	for coupled in _coupled_carriages:
		if not is_instance_valid(coupled): continue
		var cf = coupled.get_node_or_null("CoupleAreaFront")
		var cb = coupled.get_node_or_null("CoupleAreaBack")
		if cf: areas_to_check.append(cf)
		if cb: areas_to_check.append(cb)
	
	for area in areas_to_check:
		for other_area in area.get_overlapping_areas():
			var parent = other_area.get_parent()
			if parent == null: continue
			if not parent.is_in_group("train_carriage"): continue
			if _coupled_carriages.has(parent): continue
			if _nearby_carriages.has(parent): continue
			_nearby_carriages.append(parent)
	
	_nearby_carriage = _nearby_carriages[0] if _nearby_carriages.size() > 0 else null
	
func _try_couple_or_decouple() -> void:
	if _nearby_carriages.size() > 0 or _coupled_carriages.size() > 0:
		if couple_menu.visible:
			couple_menu.hide_menu()
		else:
			couple_menu.show_menu()
	
func _couple_carriage(carriage: Node) -> void:
	_coupled_carriages.append(carriage)
	carriage.couple()
	print("[Train] Angekoppelt: %s" % carriage.name)
	
func _decouple_last() -> void:
	if _coupled_carriages.is_empty(): return
	var last = _coupled_carriages.back()
	_coupled_carriages.pop_back()
	if is_instance_valid(last):
		last.decouple()
	
func _update_carriages() -> void:
	if _coupled_carriages.is_empty(): return
	
	var prev_progress = current_progress
	var prev_track    = current_track
	var prev_follow   = current_path_follow
	
	for i in range(_coupled_carriages.size()):
		var carriage = _coupled_carriages[i]
		if not is_instance_valid(carriage): continue
		carriage.leader_is_train = (i == 0)
		carriage.update_coupled_position(prev_progress, prev_track, prev_follow, speed)
		prev_progress = carriage.current_progress
		prev_track    = carriage.current_track
		prev_follow   = carriage.current_path_follow
	
func _get_total_weight() -> float:
	var total = weight_tons
	for c in _coupled_carriages:
		if is_instance_valid(c):
			total += c.get("weight") if c.get("weight") != null else 10.0
	return total
	
func _get_total_tractive_force() -> float:
	var total = tractive_force
	for c in _coupled_carriages:
		if is_instance_valid(c) and c.get("tractive_force") != null:
			total += c.get("tractive_force")
	return total
	
func _find_rail_network() -> Node:
	var node = get_parent()
	while node:
		if node.has_method("get_next_track"):
			return node
		node = node.get_parent()
	return null
	
func notify_junction_enter(junction) -> void:
	current_junction = junction
	_update_switch_hud()
	
func notify_junction_exit(junction) -> void:
	if current_junction == junction:
		current_junction = null
		if switch_hud: switch_hud.visible = false
	
func _update_next_junction() -> void:
	if not _rail_network: return
	var next_sw = _rail_network.get_next_switch_for(current_track)
	if next_sw != current_junction:
		current_junction = next_sw
	_update_switch_hud()
	
func get_nearby_carriages() -> Array:
	return _nearby_carriages
	
func get_coupled_carriages() -> Array:
	return _coupled_carriages
	
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
	
func _update_camera() -> void:
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
	
func enter_vehicle(player) -> void:
	player_ref = player
	player_inside = true
	just_entered = true
	player_ref.hide()
	player_ref.set_physics_process(false)
	player_ref.set_collision_layer_value(1, false)
	player_ref.set_collision_mask_value(1, false)
	if current_camera == 1:
		train_camera.current = true
	tooltip_layer.visible = true
	tooltip_layer_enter.visible = false
	map_hud.visible = true
	carriage_hud.visible = true
	couple_menu.visible = false
	_update_switch_hud()
	
func exit_train() -> void:
	if not player_ref: return
	tooltip_layer.visible = false
	player_inside = false
	speed = 0.0
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
	
func _on_save_loaded() -> void:
	
	# Not WORKING: Progress not correct !
	
	print(">>> _on_save_loaded() AUFGERUFEN <<<")  # DEBUG
	_rail_network = _find_rail_network()
	current_track = null
	current_path_follow = null
	
	if _rail_network and current_track_name != "":
		for child in _rail_network.get_children():
			if child is Path3D and child.name == current_track_name:
				current_track = child
				for sub in child.get_children():
					if sub is PathFollow3D:
						current_path_follow = sub
						break
				break
	
	if is_derailed:
		gravity_scale = 1.0
		_anchor = null
	else:
		gravity_scale = 0.3
		if current_path_follow:
			current_path_follow.progress = current_progress
		_create_anchor()
	
	print("After Loading - current_track: ", current_track, " | current_progress ", current_progress)
	
	for carriage in _coupled_carriages:
		if is_instance_valid(carriage) and carriage.has_method("couple"):
			carriage.couple()
