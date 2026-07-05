extends Node3D

signal direction_changed(new_direction: String)

@export var track_incoming : NodePath
@export var track_main : NodePath
@export var track_branch : NodePath

var current_direction := "main"

var _track_in : Path3D
var _track_main : Path3D
var _track_branch : Path3D

func _ready():
	if track_incoming:
		_track_in = get_node(track_incoming)
	if track_main:
		_track_main = get_node(track_main)
	if track_branch:
		_track_branch = get_node(track_branch)
	
		if not _track_in or not _track_main or not _track_branch:
			push_error("Switch: %s: Not all tracks assigned" % name)
			return
	
func switch_left(_from_track: String):
	set_direction("branch")
	
func switch_right(_from_track: String):
	set_direction("main")
	
func set_direction(dir: String):
	if current_direction == dir:
		return
	current_direction = dir
	emit_signal("direction_changed", dir)
	#print("Switch: %s -> %s" % [name, dir.to_upper()])
	
func get_next_track_for(incoming: Path3D, direction: int) -> Path3D:
	if direction == 1:
		if incoming == _track_in:
			return _track_main if current_direction == "main" else _track_branch
	elif direction == -1:
		if incoming == _track_main or incoming == _track_branch:
			return _track_in
	return null
	
func get_from_track():
	return _track_in
	
func _on_switch_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("train"):
		body.get_parent().notify_junction_enter(self)
	
func _on_switch_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("train"):
		body.get_parent().notify_junction_exit(self)
	
func get_world_position() -> Vector3:
	if has_node("SwitchPoint"):
		return $SwitchPoint.global_position
	return global_position
