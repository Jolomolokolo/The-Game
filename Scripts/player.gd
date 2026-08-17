extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.2
@export var respawn_position := Vector3(11, 0.489, 11)
@export var respawn_depth_trigger := -25

@export var fall_damage_threshold := 10.0
@export var fall_damage_multiplier := 2.0
@export var respawn_ragedoll_time := 3.0

var health := 0.0
var max_health := 100.0
var player_dead := false
var game_paused := false
var was_on_floor := false
var fall_velocity := 0.0
var displayed_cash := 100
var cash_count_tween : Tween

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_selected = 2

var in_car := false
var nearby_vehicle : Node = null

# Smooth rotation system
var cam_pitch := 0.0
var target_yaw := 0.0
var current_yaw := 0.0

# Grid System
var grid_size = 0.25
var ghost_block: Node3D = null
var objects = []
var current_object_index = 0
var ghost_rotation_y := 0.0

# Camera
@onready var camera_pivot = $CameraPivot
@onready var camera_first_view = $"CameraPivot/First-View"
@onready var camera_third_view = $"CameraPivot/SpringArm3D/Third-View"
#@onready var head_mesh = $"Skeleton3D/head-mesh"

# Control/HUD
@onready var respawn_screen = $Control/RespawnScreen
@onready var pause_screen = $PauseScreen

@onready var health_bar = $CanvasLayer/HealthBar
@onready var cash_label : Label = $CanvasLayer/CashLabel
@onready var cash_popup_container : Control = $CanvasLayer/CashPopupContainer
@onready var ui_overlay_all = $CanvasLayer

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_first_view.current = false
	camera_third_view.current = true
	max_health = GameData.start_health
	health = max_health
	health_bar.value = health
	respawn_screen.visible = false
	pause_screen.visible = false
	call_deferred("_setup_collision_exceptions")
	
	objects.append(preload("res://Scenes/GridSystem/GridSystem-TrainTracks.tscn"))
	objects.append(preload("res://Scenes/GridSystem/GridSystem-Wall.tscn"))
	objects.append(preload("res://Scenes/GridSystem/GridSystem-Object.tscn"))
	
	GameData.cash_changed.connect(_on_cash_changed)
	displayed_cash = GameData.cash
	_update_cash_label(displayed_cash)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		game_pause()
		return
	
	if not GameState.can_player_move() or GameState.current_vehicle_type != GameState.VehicleType.NONE:
		return
	
	if event is InputEventMouseMotion:
		
		target_yaw += deg_to_rad(-event.relative.x * mouse_sensitivity)
		
		cam_pitch += deg_to_rad(-event.relative.y * mouse_sensitivity)
		cam_pitch = clamp(cam_pitch, deg_to_rad(-50), deg_to_rad(50))
	
	# Camera Switch
	if event.is_action_pressed("camera_1"):
		camera_selected = 1
	if event.is_action_pressed("camera_2"):
		camera_selected = 2
	
	if event.is_action_pressed("e") and nearby_vehicle != null:
		if GameState.current_vehicle_type == GameState.VehicleType.NONE:
			set_process_unhandled_input(false)
			nearby_vehicle.enter_vehicle(self)
	
	# Intern - DELETE for Release
	
	if event.is_action_pressed("0"):
		GameState.set_state(GameState.State.UI)
	
	if event.is_action_pressed("8"):
		GameState.set_state(GameState.State.PLAYING)
	
	if event.is_action_pressed("9"):
		GameData.add_cash(100, "Button 9")
	
func _physics_process(delta):
	if not GameState.can_player_move() or GameState.current_vehicle_type != GameState.VehicleType.NONE:
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
	if Input.is_action_just_pressed("jump") and is_on_floor():
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
	
	if Input.is_action_just_pressed("build"):
		if ghost_block:
			ghost_block.destroy()
			ghost_block = null
		else:
			spawn_ghost_block()
	
	if ghost_block:
		_building(delta)
		if Input.is_action_just_pressed("next_item"):
			object_change(1)
		if Input.is_action_just_pressed("previous_item"):
			object_change(-1)
	
func _process(_delta):
	if not GameState.can_player_move():
		ui_overlay_all.visible = false
		return
	
	if GameState.current_vehicle_type != GameState.VehicleType.NONE:
		ui_overlay_all.visible = false
		return
	
	ui_overlay_all.visible = true
	
	# Camera Controll/Retraction
	var dist = global_position.distance_to(camera_third_view.global_position)
	
	if dist < 2.0:
		camera_first_view.current = true
		camera_third_view.current = false
	else:
		if camera_selected == 1:
			camera_first_view.current = true
			camera_third_view.current = false
		elif camera_selected == 2:
			camera_first_view.current = false
			camera_third_view.current = true
	
	if global_position.y < respawn_depth_trigger:
		respawn()
	
	cash_label.text = NumberFormat.format(GameData.cash)

func respawn():
	get_tree().paused = false
	global_position = respawn_position
	velocity = Vector3.ZERO
	GameState.set_state(GameState.State.PLAYING)
	$Root/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_stop_simulation()
	self.set_physics_process(true)
	respawn_screen.visible = false
	health_bar.max_value = max_health
	health_bar.value = max_health
	player_dead = false
	
func take_damage(amount: float):
	health -= amount
	health = max(health, 0.0)
	health_bar.value = health
	print("Fall Damage: -%.1f  |  HP: %.1f / %.1f" % [amount, health, max_health])
	if health <= 0.0:
		health_bar.value = 0.0
		die()

func die():
	$Root/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
	self.set_physics_process(false)
	await get_tree().create_timer(respawn_ragedoll_time).timeout
	player_dead = true
	GameState.set_state(GameState.State.UI)
	respawn_screen.visible = true
	get_tree().paused = true
	
func _setup_collision_exceptions():
	$Root/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_add_collision_exception(
		self.get_rid()
	)
	
func notify_exit():
	nearby_vehicle = null
	set_process_unhandled_input(true)
	
func _building(_delta):
	var placement = _get_placement_position(ghost_block)
	
	if placement["hit"]:
		ghost_block.visible = true
		ghost_block.global_position = placement["position"]
	else:
		ghost_block.visible = false
	
	if Input.is_action_just_pressed("rotate"):
		ghost_rotation_y += deg_to_rad(90)
		ghost_block.rotation.y = ghost_rotation_y
	
	if Input.is_action_just_pressed("left_click") and ghost_block.can_place and placement["hit"]:
		var block_instance = objects[current_object_index].instantiate()
		get_parent().add_child(block_instance)
		block_instance.place()
		block_instance.global_position = placement["position"]
		block_instance.rotation.y = ghost_rotation_y
	
func _get_placement_position(ghost: Node3D) -> Dictionary:
	var camera = camera_first_view if camera_first_view.current else camera_third_view
	var space_state = get_world_3d().direct_space_state
	
	var ray_lenght = 10.0
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -ray_lenght
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4
	query.exclude = [self.get_rid()]
	if ghost_block:
		query.exclude.append(ghost_block.get_rid())
	# To include certain surfaces, activate collisionlayer 3 on the object
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var size = _get_rotated_size(ghost.size, ghost_rotation_y)
		var normal: Vector3 = result.normal
		var placement_pos: Vector3
		if ghost.pivot_at_bottom:
			placement_pos = result.position + normal * (abs(normal.x) * size.x / 2.0 + abs(normal.z) * size.z / 2.0)
		else:
			var offset_amount = abs(normal.x) * size.x + abs(normal.y) * size.y + abs(normal.z) * size.z
			placement_pos = result.position + normal * (offset_amount / 2.0)
		return {"position": _snap_to_grid_pivot(placement_pos, size, grid_size, ghost.pivot_at_bottom), "hit": true}
	else:
		return {"hit": false}
	
func _snap_to_grid_pivot(raw_position: Vector3, size: Vector3, grid_snap: float, pivot_at_bottom: bool) -> Vector3:
	var corner : Vector3
	if pivot_at_bottom:
		corner = raw_position - Vector3(size.x / 2.0, 0,size.z / 2.0)
	else:
		corner = raw_position - size / 2.0
	
	corner.x = round(corner.x / grid_snap) * grid_snap
	corner.y = round(corner.y / grid_snap) * grid_snap
	corner.z = round(corner.z / grid_snap) * grid_snap
	
	if pivot_at_bottom:
		return corner + Vector3(size.x / 2.0, 0, size.z / 2.0)
	else:
		return corner + size / 2.0
	
func _get_rotated_size(base_size: Vector3, rotation_y: float) -> Vector3:
	var steps = round(rotation_y / (PI / 2.0))
	var is_odd_quarter_turn = int(steps) % 2 != 0
	if is_odd_quarter_turn:
		return Vector3(base_size.z, base_size.y, base_size.x)
	return base_size
	
func spawn_ghost_block():
	ghost_block = objects[current_object_index].instantiate()
	get_parent().add_child(ghost_block)
	ghost_rotation_y = 0.0
	ghost_block.rotation.y = ghost_rotation_y
	var placement = _get_placement_position(ghost_block)
	if placement["hit"]:
		ghost_block.global_position = placement["position"]
	
func object_change(direction):
	if ghost_block:
		ghost_block.queue_free()
		current_object_index += direction
		if current_object_index < 0:
			current_object_index += objects.size()
		elif current_object_index >= objects.size():
			current_object_index -= objects.size()
		spawn_ghost_block()
	
func _on_respawn_button_pressed() -> void:
	respawn()
	
func game_pause(): #  SHORTCUT adden, aber ESC braucht Delay, da sonst direkt Pause rückgänig gemacht
	pause_screen.visible = true
	game_paused = true
	GameState.set_state(GameState.State.PAUSED)
	get_tree().paused = true
	
func game_pause_return():
	get_tree().paused = false
	game_paused = false
	pause_screen.visible = false
	GameState.set_state(GameState.State.PLAYING)
	ui_overlay_all.visible = false
	
func _on_return_button_pressed() -> void:
	game_pause_return()
	
func _on_cash_changed(new_value: int, difference: int) -> void:
	_spawn_cash_popup(difference)
	_animate_cash_count_to(new_value)
	
func _spawn_cash_popup(difference: int):
	if difference == 0:
		return
	
	var popup = Label.new()
	var sign_str = "+" if difference > 0 else ""
	popup.text = sign_str + NumberFormat.format(abs(difference))
	popup.modulate = Color(1, 0.3, 0.3) if difference < 0 else Color(0.3, 1, 0.3)
	popup.add_theme_font_size_override("font_size", 20)
	
	cash_popup_container.add_child(popup)
	popup.position = Vector2(randf_range(-10, 10), 0)
	
	var popup_tween = create_tween()
	popup_tween.tween_property(popup, "position:y", popup.position.y - 30, 0.6)
	popup_tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.6).set_delay(0.3)
	popup_tween.tween_callback(popup.queue_free)
	
func _animate_cash_count_to(target_cash: int):
	if cash_count_tween:
		cash_count_tween.kill()
	
	cash_count_tween = create_tween()
	cash_count_tween.tween_method(_update_cash_label, displayed_cash, target_cash, 0.5)
	cash_count_tween.finished.connect(func(): displayed_cash = target_cash)
	
func _update_cash_label(value: float):
	displayed_cash = int(round(value))
	cash_label.text = NumberFormat.format(displayed_cash)
	
func _on_return_main_button_pressed() -> void:
	SceneManager.change_scene("res://Scenes/HUDs/StartPage.tscn")
	
