class_name JsonHelper


static func get_vector3(
	dict: Dictionary, key_name: String = "", fallback_value = Vector3(0, 0, 0)
) -> Vector3:
	var value = fallback_value
	var raw_data = dict

	if key_name != "":
		if not dict.has(key_name):
			return value

		raw_data = dict[key_name]
		if not raw_data:
			return value

	if raw_data.has("x"):
		value.x = float(raw_data["x"])

	if raw_data.has("y"):
		value.y = float(raw_data["y"])

	if raw_data.has("z"):
		value.z = float(raw_data["z"])

	return value


static func get_vector2(
	dict: Dictionary, key_name: String = "", fallback_value = Vector2(0, 0)
) -> Vector2:
	var value = fallback_value
	var raw_data = dict

	if key_name != "":
		if not dict.has(key_name):
			return value

		raw_data = dict[key_name]
		if not raw_data:
			return value

	if raw_data.has("x"):
		value.x = float(raw_data["x"])

	if raw_data.has("y"):
		value.y = float(raw_data["y"])

	return value


static func get_optional_value(dict: Dictionary, key_name: String, fallback_value = null) -> Object:
	if not dict.has(key_name):
		return fallback_value

	return dict[key_name]


static func get_optional_number(dict: Dictionary, key_name: String, fallback_value = 0.0) -> float:
	if not dict.has(key_name):
		return fallback_value

	var value = dict[key_name]
	if not (value is float) and not (value is int):
		print(
			(
				"%s is not a number but a %s;using the default value %f"
				% [key_name, get_type_string(value), fallback_value]
			)
		)
		return fallback_value

	return float(dict[key_name])


static func get_optional_int(dict: Dictionary, key_name: String, fallback_value = 0) -> int:
	return int(get_optional_number(dict, key_name, fallback_value))


static func get_optional_enum(
	dict: Dictionary, key_name: String, enum_type: Dictionary, fallback_value
) -> int:
	if not dict.has(key_name):
		return fallback_value

	var value = dict[key_name]
	if not (value is int) and not (value is String):
		print(
			(
				"%s is not an enum but a %s;using the default value %d"
				% [key_name, get_type_string(value), fallback_value]
			)
		)
		return fallback_value

	if value is int:
		if not enum_type.values().has(value):
			print(
				"%d is not a valid enum value;using the default value %d" % [value, fallback_value]
			)
			return fallback_value

		return value

	if not enum_type.has(value):
		print("%s is not a valid enum value;using the default value %d" % [value, fallback_value])
		return fallback_value

	return enum_type[value]


static func get_optional_bool(dict: Dictionary, key_name: String, fallback_value = false) -> bool:
	if not dict.has(key_name):
		return fallback_value

	var value = dict[key_name]
	if not (value is bool):
		print(
			(
				"%s is not a boolean but a %s;using the default value %s"
				% [key_name, get_type_string(value), fallback_value]
			)
		)
		return fallback_value

	return value


static func dict_deep_copy(dict: Dictionary) -> Dictionary:
	var new_dict = {}

	for key in dict.keys():
		var value = dict[key]
		if value is Dictionary:
			new_dict[key] = dict_deep_copy(value)
		elif value is Array:
			new_dict[key] = array_deep_copy(value)
		else:
			new_dict[key] = value

	return new_dict


static func array_deep_copy(array: Array) -> Array:
	var new_array = []

	for value in array:
		if value is Dictionary:
			new_array.append(dict_deep_copy(value))
		elif value is Array:
			new_array.append(array_deep_copy(value))
		else:
			new_array.append(value)

	return new_array


static func get_type_string(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "nil"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "string"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR2I:
			return "Vector2i"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_VECTOR3I:
			return "Vector3i"
		TYPE_TRANSFORM2D:
			return "Transform2D"
		TYPE_VECTOR4:
			return "Vector4"
		TYPE_VECTOR4I:
			return "Vector4i"
		TYPE_PLANE:
			return "Plane"
		TYPE_QUATERNION:
			return "Quaternion"
		TYPE_AABB:
			return "AABB"
		TYPE_BASIS:
			return "Basis"
		TYPE_TRANSFORM3D:
			return "Transform3D"
		TYPE_PROJECTION:
			return "Projection"
		TYPE_COLOR:
			return "Color"
		TYPE_STRING_NAME:
			return "StringName"
		TYPE_NODE_PATH:
			return "NodePath"
		TYPE_RID:
			return "RID"
		TYPE_OBJECT:
			return "Object"
		TYPE_CALLABLE:
			return "Callable"
		TYPE_SIGNAL:
			return "Signal"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_ARRAY:
			return "Array"
		TYPE_PACKED_BYTE_ARRAY:
			return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY:
			return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY:
			return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY:
			return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY:
			return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY:
			return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY:
			return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY:
			return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY:
			return "PackedColorArray"
		TYPE_PACKED_VECTOR4_ARRAY:
			return "PackedVector4Array"

		_:
			return "invalid"
