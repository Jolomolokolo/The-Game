extends Node3D
class_name RailSignal

enum State { STOP, CAUTION, CLEAR }

@export var current_state : State = State.STOP : set = _set_state
@export var monitored_track : NodePath
@export var auto_mode : bool = true
@export var emergency_brake_distance := 15.0

@onready var lens_red : MeshInstance3D = $MeshLightRed
@onready var lens_yellow : MeshInstance3D = $MeshLightYellow
@onready var lens_green : MeshInstance3D = $MeshLightGreen

var off_material : StandardMaterial3D
var mat_red : StandardMaterial3D
var mat_yellow : StandardMaterial3D
var mat_green : StandardMaterial3D

var _monitored_track_node : Path3D = null
var _rail_network : Node = null

func _ready():
	_build_materials()
	_set_state(current_state)
	
	var node = get_parent()
	while node:
		if node.has_method("get_next_track"):
			_rail_network = node
			break
		node = node.get_parent()
	
	if monitored_track:
		_monitored_track_node = get_node(monitored_track)
	
func _process(_delta: float):
	if Input.is_action_just_pressed("7"):
		auto_mode = false
		_set_state(State.STOP)
	if Input.is_action_just_pressed("8"):
		auto_mode = false
		_set_state(State.CAUTION)
	if Input.is_action_just_pressed("9"):
		auto_mode = false
		_set_state(State.CLEAR)
		
	if auto_mode:
		_update_auto_mode()
	
	if current_state == State.STOP:
		_check_emergency_brake()
	
func _update_auto_mode():
	if not _monitored_track_node or not _rail_network:
		return
	
	var next_track = _rail_network.get_next_track(_monitored_track_node, 1)
	if next_track == null:
		_set_state(State.STOP)
		return
	
	var next_occupied  = is_track_occupied(next_track)
	if next_occupied:
		_set_state(State.STOP)
	
	var next_next_track = _rail_network.get_next_track(next_track, 1)
	if next_track != null:
		var next_next_occupied = is_track_occupied(next_next_track)
		if next_next_occupied:
			_set_state(State.CAUTION)
			return
	
	_set_state(State.CLEAR)
	
func is_track_occupied(track: Path3D) -> bool:
	if track == null:
		return false
		
	for train in get_tree().get_nodes_in_group("train"):
		var ct = train.get("current_track")
		if ct == null:
			continue
		if ct.name == track.name:
			return true
		
	for carriage in get_tree().get_nodes_in_group("train_carriage"):
		var ct = carriage.get("current_track")
		if ct == null:
			continue
		if ct.name == track.name:
			return true
		
	return false
	
func _check_emergency_brake():
	if not _monitored_track_node:
		return
	
	var signal_pos = global_position
	
	for train in get_tree().get_nodes_in_group("train"):
		if not is_instance_valid(train):
			continue
		if train.get("current_track") == null:
			continue
		if train.current_track.name != _monitored_track_node.name:
			continue
		
		var dist = signal_pos.distance_to(train.global_position)
		if dist < emergency_brake_distance and train.get("speed") != null:
			var to_signal = (signal_pos - train.global_position).normalized()
			var train_dir = -train.global_transform.basis.z
			if to_signal.dot(train_dir) > 0.3:
				train.speed = move_toward(train.speed, 0.0, abs(train.speed) * 0.3 + 2.0)
				print("Signal: Emergency Brake")
	
func _build_materials():
	off_material = StandardMaterial3D.new()
	off_material.albedo_color = Color(0.12, 0.12, 0.12)
	mat_red = _make_glow_material(Color(1, 0, 0))
	mat_yellow = _make_glow_material(Color(1, 0.8, 0))
	mat_green = _make_glow_material(Color(0, 1, 0))
	
func _make_glow_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	return mat
	
func _set_state(new_state: State):
	current_state = new_state
	
	if not is_node_ready():
		return
	
	lens_red.material_override = mat_red if new_state == State.STOP else off_material
	lens_yellow.material_override = mat_yellow if new_state == State.CAUTION else off_material
	lens_green.material_override = mat_green if new_state == State.CLEAR else off_material
