# Betankungsanlage für die Loks, eventuell mit Wasser für alte Loks - Dampfloks

extends Node3D

@export var hook_point : Node
@export var lift_speed := 2.0

@onready var crane_arm = $"Crane/crane/CraneArm"
@onready var crane_arm_magnet = $"Crane/crane/CraneArm/arm/CraneMagnet"

var carriages_touching_fence_front : Array[Node3D] = []
var carriages_touching_fence_back : Array[Node3D] = []
var carriages_in_main_area : Array[Node3D] = []

var held_container : RigidBody3D = null
var _nearby_containers : Array[RigidBody3D] = []

func _process(_delta: float) -> void:
	
	# TEST SETUP - DELETE FOR RELEASE
	if Input.is_action_just_pressed("0"):
		crane_arm_magnet.position.y = crane_arm_magnet.position.y - 5
		crane_arm.rotate_y(180)
		await get_tree().create_timer(5).timeout
		crane_arm_magnet.position.y = crane_arm_magnet.position.y + 5
		crane_arm.rotate_y(-180)
		
	if not Input.is_action_just_pressed("e"):
		return
	
	for carriage in carriages_in_main_area:
		if carriage in carriages_touching_fence_front:
			continue
		if carriage in carriages_touching_fence_back:
			continue
		if held_container:
			_drop_container()
		else:
			_try_grab_container()
		#start_discharge(carriage)
		break
	
func _try_grab_container():
	if _nearby_containers.is_empty():
		return
	
	var container := _nearby_containers[0]
	held_container = container
	
	container.freeze = true
	container.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	
	container.get_parent().remove_child(container)
	hook_point.add_child(container)
	container.position = Vector3.ZERO
	
func _drop_container():
	if not held_container:
		return
	
	var drop_transform := held_container.global_transform
	hook_point.remove_child(held_container)
	get_tree().current_scene.add_child(held_container)
	held_container.global_transform = drop_transform
	
	held_container.freeze = false
	held_container = null
	
func _on_main_discharge_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_in_main_area.append(body)
	
func _on_main_discharge_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_in_main_area.erase(body)
	
func _on_fence_discharge_area_front_body_entered(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_touching_fence_front.append(body)
	
func _on_fence_discharge_area_front_body_exited(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_touching_fence_front.erase(body)
	
func _on_fence_discharge_area_back_body_entered(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_touching_fence_back.append(body)
	
func _on_fence_discharge_area_back_body_exited(body: Node3D) -> void:
	if body.is_in_group("train_carriage"):
		carriages_touching_fence_back.erase(body)
	
func start_discharge(carriage: Node3D) -> void:
	print("Now Discharge: ", carriage.name)
	# Need to lower something EXACT on the height of the cargo
	
