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

var health := 0.0
var was_on_floor := false
var fall_velocity := 0.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_selected = 2

var in_car := false
var nearby_vehicle : Node = null

# Smooth rotation system
var cam_pitch := 0.0
var target_yaw := 0.0
var current_yaw := 0.0

# Camera
@onready var camera_pivot = $CameraPivot
@onready var camera_first_view = $"CameraPivot/First-View"
@onready var camera_third_view = $"CameraPivot/SpringArm3D/Third-View"
#@onready var head_mesh = $"Skeleton3D/head-mesh"

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_first_view.current = false
	camera_third_view.current = true
	#head_mesh.visible = true
	health = max_health
	call_deferred("_setup_collision_exceptions")
	
func _input(event):
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not in_car:

		target_yaw += deg_to_rad(-event.relative.x * mouse_sensitivity)

		cam_pitch += deg_to_rad(-event.relative.y * mouse_sensitivity)
		cam_pitch = clamp(cam_pitch, deg_to_rad(-50), deg_to_rad(50))

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
	
	if event.is_action_pressed("ui_interact") and nearby_vehicle != null:
		if not in_car:
			in_car = true
			set_process_unhandled_input(false)
			nearby_vehicle.enter_vehicle(self)
	
func _physics_process(delta):
	if in_car:
		return
	
	# Smooth body rotation
	camera_pivot.rotation.x = cam_pitch
	current_yaw = lerp_angle(current_yaw, target_yaw, 10.0 * delta)
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
		velocity.x *= 0.45
		velocity.z *= 0.45
		animation_player.play("anmimationes/Root_Jump")
	
	# Input
	var input_dir = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down")
	
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
	if direction and is_on_floor() and not Input.is_action_just_pressed("ui_accept"):
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	
		if is_on_floor():
			if current_speed == sprint_speed:
				if animation_player.current_animation != "anmimationes/Root_Run" and animation_player.current_animation != "anmimationes/Root_Jump":
					animation_player.speed_scale = 1.0
					animation_player.play("anmimationes/Root_Run")
			else:
				if animation_player.current_animation != "anmimationes/Root_Run" and animation_player.current_animation != "anmimationes/Root_Jump":
					animation_player.speed_scale = 0.6
					animation_player.play("anmimationes/Root_Run")
	
	elif is_on_floor() and not Input.is_action_just_pressed("ui_accept"):
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
		if is_on_floor():
			if animation_player.current_animation != "anmimationes/Root_Idle" and animation_player.current_animation != "anmimationes/Root_Jump":
				animation_player.speed_scale = 0.6
				animation_player.play("anmimationes/Root_Idle")
	
	move_and_slide()
	
func _process(_delta):
	
	if in_car:
		return
	
	# Camera Controll/Retraction
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
	print("DEAD") # Adden von physic off
	$Root/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
	self.set_physics_process(false)
	
func _setup_collision_exceptions():
	$Root/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_add_collision_exception(
		self.get_rid()
	)
	
func notify_exit():
	in_car = false
	nearby_vehicle = null
	set_process_unhandled_input(true)
