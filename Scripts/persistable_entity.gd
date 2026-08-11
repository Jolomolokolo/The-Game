extends Node3D
class_name PersistableEntity

@export var entity_id : String = ""
@export var hp : int = 100

const _EXCLUDED_PROPERTIES := ["entity_id"]

func _ready() -> void:
	if entity_id == "":
		entity_id = _generate_id()
	add_to_group("Persist")
	
func _generate_id() -> String:
	return "%s_%d_%d" % [
		scene_file_path.get_file().get_basename(),
		Time.get_ticks_usec(),
		randi()
	]
	
func save() -> Dictionary:
	var data : Dictionary = {
		"id": entity_id, 
		"scene": scene_file_path,
		"position": var_to_str(global_position),
		"rotation": var_to_str(global_rotation),
		"propertes": {}
	}
	
	for prop in _get_exported_properties():
		data["properties"][prop] = _encode_value(get(prop))
	
	return data
	
func load_data(data: Dictionary) -> void:
	var properties : Dictionary = data.get("properties", {})
	for prop in properties.keys():
		if not _is_reference_value(properties[prop]):
			set(prop, _decode_value(properties[prop], {}))
	
func restore_links(data: Dictionary, id_to_node: Dictionary) -> void:
	var properties : Dictionary = data.get("properties", {})
	for prop in properties.keys():
		if _is_reference_value(properties[prop]):
			set(prop, _decode_value(properties[prop], id_to_node))
	
func _get_exported_properties() -> Array[String]:
	var result: Array[String] = []
	for prop in _get_property_list():
		var usage: int = prop["usage"]
		if usage and PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
			var name : String = prop["name"]
			if name not in _EXCLUDED_PROPERTIES:
				result.append(name)
	return result
	
func _encode_value(value):
	if value is PersistableEntity:
		return {"__ref__": value.entity_id}
	
	if value is Array:
		var out : Array = []
		for item in value:
			out.append(_encode_value(item))
		return out
	
	if value is Dictionary:
		var out : Dictionary = {}
		for key in value.keys():
			out[key] = _encode_value(value[key])
		return out
		
	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4, TYPE_COLOR, TYPE_BASIS, \
		TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_QUATERNION, TYPE_PLANE, \
		TYPE_RECT2, TYPE_AABB, TYPE_NODE_PATH:
			return {"__variant__": var_to_str(value)}
		_:
			return value
	
func _decode_value(value, id_to_node: Dictionary):
	if value is Dictionary:
		if value.has("__ref__"):
			return id_to_node.get(value["__ref__"], null)
		if value.has("__variant__"):
			return str_to_var(value["__variant__"])
		
		var out : Dictionary = {}
		for key in value.keys():
			out[key] = _decode_value(value[key], id_to_node)
		return out
	
	if value is Array:
		var out : Array = []
		for item in value:
			out.append(_decode_value(item, id_to_node))
		return out
	return value
	
func _is_reference_value(value) -> bool:
	if value is Dictionary and value.has("__ref__"):
		return true
	if value is Array:
		for item in value:
			if _is_reference_value(item):
				return true
	return false
	
