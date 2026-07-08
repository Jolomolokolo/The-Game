extends StaticBody3D

@export var size : Vector3 = Vector3(1, 1, 1)
@export var pivot_at_bottom : bool = true

@onready var model : MeshInstance3D = $Model
@onready var collision_shape : CollisionShape3D = $CollisionShape3D
@onready var clipping_hitbox : Area3D = $ClippingHitbox
@onready var floating_hitbox : Area3D = $FloatingHitbox

var red_material : Material = load("res://Scenes/GridSystem/Red.tres")
var green_material : Material = load("res://Scenes/GridSystem/Green.tres")

var can_place := true

func _process(_delta: float):
	if clipping_hitbox:
		model.transparency = 0.6
		can_place = clipping_hitbox.get_overlapping_bodies().is_empty() and not floating_hitbox.get_overlapping_bodies().is_empty()
		if can_place:
			model.material_override = green_material
		else:
			model.material_override = red_material
	
func place():
	clipping_hitbox.queue_free()
	floating_hitbox.queue_free()
	model.material_override = null
	model.transparency = 0.0
	collision_shape.disabled = false
	
func destroy():
	queue_free()
