extends RigidBody3D

@export var spacing := 7.60
@export var spacing_carriage := 8.0
@export var wobble_amount := 0.05
@export var wobble_speed := 5.0
@export var friction := 3.0
@export var weight := 10.0 # Change at loading condition

@export var spring_strength := 800.0
@export var spring_damping := 120.0
@export var derail_distance := 5.0
@export var derail_speed_distance := 100.0

var current_track : Path3D = null
var current_path_follow : PathFollow3D = null
var current_progress : float = 0.0
var is_coupled := false
var is_derailed := false
var _wobble_time := 0.0
var _current_speed := 0.0
var _next_track : Path3D = null
var _next_follow : PathFollow3D = null
var leader_is_train := true
var velocity := 0.0

var _anchor : Node3D = null
var _time_alive := 0.0
var _derail_grace_time := 2.0

func _ready():
	add_to_group("train_carriage")
	gravity_scale = 0.3
	mass = weight
	_init_from_parent()
	
func _init_from_parent():
	var parent = get_parent()
	if parent is PathFollow3D:
		current_path_follow = parent
		var grandparent = parent.get_parent()
		if grandparent is Path3D:
			current_track = grandparent
			current_progress = current_path_follow.progress
	_create_anchor()
	
func _create_anchor() -> void:
	_anchor = Marker3D.new()
	_anchor.name = "CarriageAnchor_" + name
	if current_path_follow:
		current_path_follow.add_child.call_deferred(_anchor)
	if _anchor:
		global_position = _anchor.global_position
	
func _physics_process(delta: float) -> void:
	_time_alive += delta
	
	if is_derailed:
		return
	
	if current_path_follow:
		current_path_follow.progress = current_progress
	
	if _anchor:
		_apply_spring_force(delta)
	
	if _time_alive > _derail_grace_time:
		_check_derailment()
	
func _apply_spring_force(delta: float) -> void:
	if not _anchor:
		return
	
	var target_pos = _anchor.global_position
	var diff = target_pos - global_position
	var dist = diff.length()
	
	var spring_force = diff.normalized() * dist * spring_strength
	var damping_force = - linear_velocity * spring_damping
	
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
	
func _derail() -> void:
	if is_derailed:
		return
	is_derailed = true
	gravity_scale = 1.0
	_anchor = null
	print("Carriage %s DERAILED" % name)
	
func _process(delta: float) -> void:
	if is_derailed or is_coupled:
		if wobble_amount > 0 and is_coupled:
			_wobble_time += delta * wobble_speed
			var wobble = sin(_wobble_time) * wobble_amount * abs(_current_speed) * 0.05
			rotation.z = wobble
		return
	
	if abs(velocity) > 1.1:
		current_progress += velocity * delta
		current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length() if current_track else 0.0)
		if current_path_follow:
			current_path_follow.progress = current_progress
		velocity = move_toward(velocity, 0.0, friction * delta)
	else:
		velocity = 0.0
	_check_carriage_collision()
	
func update_coupled_position(leader_progress: float, leader_track: Path3D, leader_follow: PathFollow3D, spd: float) -> void:
	_current_speed = spd
	var going_forward = spd > 0.0
	var delta = get_process_delta_time()
	
	var target = leader_progress - (spacing if leader_is_train else spacing_carriage)
	
	if _next_track != null:
		current_progress += spd * delta
		var track_length = current_track.curve.get_baked_length()
	
		if going_forward and current_progress >= track_length - 0.1:
			_move_to_track(_next_track, _next_follow)
			current_progress = 0.0
			_next_track = null
			_next_follow = null
		elif not going_forward and current_progress <= 0.1:
			var next_length = _next_track.curve.get_baked_length()
			_move_to_track(_next_track, _next_follow)
			current_progress = next_length
			_next_track = null
			_next_follow = null
		
		current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length())
		if current_path_follow:
			current_path_follow.progress = current_progress
		return
	
	if leader_track.name == current_track.name:
		var rn = current_track.get_parent()
		if rn and rn.has_method("get_next_track"):
			if going_forward and target >= current_track.curve.get_baked_length() - 0.1:
				var next = rn.get_next_track(current_track, 1)
				if next and _next_track == null:
					for child in next.get_children():
						if child is PathFollow3D:
							_next_track = next
							_next_follow = child
							break
			elif not going_forward and target <= 0.1:
				var prev = rn.get_next_track(current_track, -1)
				if prev and _next_track == null:
					for child in prev.get_children():
						if child is PathFollow3D:
							_next_track = prev
							_next_follow = child
							break
		
		current_progress = clampf(target, 0.0, current_track.curve.get_baked_length())
		if current_path_follow:
			current_path_follow.progress = current_progress
	else:
		current_progress += spd * delta
		current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length())
		if current_path_follow:
			current_path_follow.progress = current_progress
	
		var track_length = current_track.curve.get_baked_length()
		if going_forward and current_progress >= track_length - 0.1:
			_move_to_track(leader_track, leader_follow)
			current_progress = 0.0
			if current_path_follow:
				current_path_follow.progress = current_progress
		elif not going_forward and current_progress <= 0.1:
			_move_to_track(leader_track, leader_follow)
			current_progress = leader_track.curve.get_baked_length()
			if current_path_follow:
				current_path_follow.progress = current_progress
	
func _move_to_track(new_track: Path3D, reference_follow: PathFollow3D) -> void:
	var new_follow = PathFollow3D.new()
	new_follow.name = "CarriageFollow_" + name
	new_follow.rotation_mode = reference_follow.rotation_mode
	new_follow.loop = reference_follow.loop
	new_track.add_child(new_follow)
	
	if current_path_follow:
		current_path_follow.remove_child(self)
		if current_path_follow.name.begins_with("CarriageFollow_"):
			current_path_follow.queue_free()
	
	new_follow.add_child(self)
	transform = Transform3D.IDENTITY
	current_track = new_track
	current_path_follow = new_follow
	
func couple():
	is_coupled = true
	print("Carriage: %s coupled" % name)
	
func decouple():
	is_coupled = false
	_next_track = null
	_next_follow = null
	_wobble_time = 0.0
	rotation.z = 0.0
	#print("Carriage %s decoupled at progress: %.1f on %s" % [name, current_progress, current_track.name if current_track else "?"])
	
func get_couple_position() -> Vector3:
	return global_position
	
func _check_carriage_collision():
	var all_carriages = get_tree().get_nodes_in_group("train_carriage")
	for other in all_carriages:
		if other == self:
			continue
		if not is_instance_valid(other):
			continue
		if other.current_track.name != current_track.name:
			continue
		if is_coupled and other.is_coupled:
			continue
		
		var dist = current_progress - other.current_progress
		var abs_dist = abs(dist)
		var min_dist = spacing_carriage
		
		if abs_dist < min_dist:
			var moving_toward = (velocity > 0 and dist > 0) or (velocity < 0 and dist < 0)
			
			if moving_toward:
				velocity = 0.0
			
			var push_dir = sign(dist)
			if push_dir == 0:
				push_dir = 1
			current_progress = other.current_progress + min_dist * push_dir
			current_progress = clampf(current_progress, 0.0, current_track.curve.get_baked_length() if current_track else 0.0)
			if current_path_follow:
				current_path_follow.progress = current_progress
			return
