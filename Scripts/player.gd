extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.2
@export var respawn_position := Vector3(11, 0.489, 11)
@export var respawn_depth_trigger := -25

@export var fall_damage_threshold := 10.0
@export var fall_damage_multiplier := 2.0
@export var max_health := 100.0
@export var respawn_delay := 3.0

var health := 100.0
var was_on_floor := false
var fall_velocity := 0.0
var is_dead := false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_selected = 2

# Smooth rotation system
var cam_pitch := 0.0
var target_yaw := 0.0
var current_yaw := 0.0

# Camera
@onready var camera_pivot = $CameraPivot
@onready var camera_first_view = $"CameraPivot/First-View"
@onready var camera_third_view = $"CameraPivot/SpringArm3D/Third-View"
#@onready var head_mesh = $"Skeleton3D/head-mesh"
@onready var skeleton : Skeleton3D = $Root/Skeleton3D
@onready var bone_simulator : PhysicalBoneSimulator3D = $Root/Skeleton3D/PhysicalBoneSimulator3D

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_first_view.current = false
	camera_third_view.current = true
	#head_mesh.visible = true

func _input(event):
	if is_dead:
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		target_yaw += deg_to_rad(-event.relative.x * mouse_sensitivity)

		cam_pitch += deg_to_rad(-event.relative.y * mouse_sensitivity)
		cam_pitch = clamp(cam_pitch, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Camera Switch
	if event.is_action_pressed("camera_1"):
		camera_selected = 1
	
	if event.is_action_pressed("camera_2"):
		camera_selected = 2

func _physics_process(delta):
	if is_dead:
		return
		
	# Smooth body rotation
	camera_pivot.rotation.x = cam_pitch
	current_yaw = lerp_angle(current_yaw, target_yaw, 0.08)
	rotation.y = current_yaw
	
	# Fallspeed
	if not is_on_floor():
		fall_velocity = min(velocity.y, fall_velocity)
	
	# Gravitation
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Fall Damage
	if is_on_floor() and not was_on_floor:
		var impact_speed = abs(fall_velocity)
		if impact_speed > fall_damage_threshold:
			var damage = (impact_speed - fall_damage_threshold) * fall_damage_multiplier
			take_damage(damage)
		fall_velocity = 0.0
	
	# Jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		animation_player.play("anmimationes/Root_Jump")
	
	# Input
	var input_dir = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	
	# Movement direction
	var direction = (
		Basis(Vector3.UP, current_yaw) *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()
	
	# Sprint
	var current_speed = walk_speed
	
	if Input.is_action_pressed("sprint"):
		if not is_on_floor():
			current_speed = walk_speed
		else:
			current_speed = sprint_speed
	
	# Motion
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	
		if is_on_floor():
			if current_speed == sprint_speed:
				animation_player.play("anmimationes/Root_Run")
			else:
				animation_player.play("anmimationes/Root_Run")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
		if is_on_floor():
			animation_player.play("anmimationes/Root_Idle")
	
	move_and_slide()
	
func _process(_delta):
	if is_dead:
		return
	
	#Camera Controll/Retraction
	var dist = global_position.distance_to(camera_third_view.global_position)
	
	if dist < 2.0:
		camera_first_view.current = true
		camera_third_view.current = false
		#head_mesh.visible = false
	else:
		if camera_selected == 1:
			camera_first_view.current = true
			camera_third_view.current = false
			#head_mesh.visible = false
		elif camera_selected == 2:
			camera_first_view.current = false
			camera_third_view.current = true
			#head_mesh.visible = true
	
	if global_position.y < respawn_depth_trigger:
		respawn()

func respawn():
	global_position = respawn_position 
	velocity = Vector3.ZERO
	
func take_damage(amount: float):
	health -= amount
	health = max(health, 0.0)
	print("Fall Damage: -%.1f  |  HP: %.1f / %.1f" % [amount, health, max_health])
	if health <= 0.0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	print("Dead! Ragdoll active...")
	
	velocity = Vector3.ZERO
	set_physics_process(false)
	
	animation_player.stop()
	_enable_ragdoll()
	
	await get_tree().create_timer(respawn_delay).timeout
	_disable_ragdoll()
	respawn()

func _enable_ragdoll():
	$CollisionShape3D.disabled = true
	
	animation_player.stop()
	animation_player.active = false
	
	bone_simulator.active = true
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for bone in bone_simulator.get_children():
		if bone is PhysicalBone3D:
			bone.linear_velocity = Vector3.ZERO
			bone.angular_velocity = Vector3.ZERO
			bone.sleeping = true
	
	await get_tree().physics_frame
	for bone in bone_simulator.get_children():
		if bone is PhysicalBone3D:
			bone.sleeping = false
			
func _disable_ragdoll():
	bone_simulator.active = false
	animation_player.active = true
	$CollisionShape3D.disabled = false
	set_physics_process(true)
	is_dead = false
	health = max_health
