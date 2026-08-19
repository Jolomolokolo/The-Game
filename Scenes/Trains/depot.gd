extends Node3D
class_name Depot

signal train_entered(depot, train)
signal train_exited(depot, train)

@export var depot_name := "Depot A"
@export var depot_id := "depot_a"
@export var track_name := "Track_A"
@export var required_progress_min := 0.0
@export var required_progress_max := 20.0

var train_inside : Array[Node] = []
var is_occupied := false

func _ready() -> void:
	var rn = _find_rail_network()
	if rn and rn.has_method("register_depot"):
		rn.register_depot(self)
	
	print("Depot: %s ready" % depot_name)
	
func _on_depot_area_body_entered(body: Node3D) -> void:
	var train = _get_train(body)
	if train == null:
		return
	if train_inside.has(train):
		return
	train_inside.append(train)
	is_occupied = true
	emit_signal("train_entered", self, train)
	print("Depot: %s: Train '%s' arrived" % [depot_name, train.name])
	
	# QUEST System
	
func _on_depot_area_body_exited(body: Node3D) -> void:
	var train = _get_train(body)
	if train == null:
		return
	train_inside.erase(train)
	is_occupied = train_inside.size() > 0
	emit_signal("train_exited", self, train)
	print("Depot: %s: Train '%s' departured" % [depot_name, train.name])
	
func _get_train(body: Node3D) -> Node:
	if body.is_in_group("train"):
		return body
	if body.get_parent() and body.get_parent().is_in_group("train"):
		return body.get_parent()
	return null
	
func get_trains() -> Array:
	return train_inside
	
func _find_rail_network() -> Node:
	var node = get_parent()
	while node:
		if node.has_method("get_next_track"):
			return node
		node = node.get_parent()
	return null
	
