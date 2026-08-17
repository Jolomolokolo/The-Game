extends RefCounted
class_name NumberFormat

static func format(value: float, currency: bool = true) -> String:
	var sign_str := "-" if value < 0 else ""
	var abs_value := absf(value)
	
	var result : String
	
	if abs_value >= 1_000_000_000:
		result = sign_str + _format_short(abs_value / 1_000_000_000.0, "B")
	elif abs_value >= 1_000_000:
		result = sign_str + _format_short(abs_value / 1_000_000.0, "M")
	elif abs_value >= 1_000:
		result = sign_str + _format_short(abs_value / 1_000.0, "K")
	else:
		result = sign_str + str(int(round(abs_value)))
	
	if currency:
		result += " €"
	
	return result
	
static func _format_short(value: float, suffix: String) -> String:
	var rounded := snappedf(value, 0.1)
	if rounded == floor(rounded):
		return "%d%s" % [int(rounded), suffix]
	return "%.1f%s" % [rounded, suffix]
	
