#include "identifier.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Identifier::_bind_methods() {
	ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	ClassDB::bind_static_method("Identifier", D_METHOD("for_resource", "_resource_path"), &Identifier::for_resource);

	ClassDB::bind_static_method("Identifier", D_METHOD("get_content_type_from_resouce", "_name"), &Identifier::get_content_type_from_resouce);
	ClassDB::bind_static_method("Identifier", D_METHOD("get_resource_prefix_from_type", "_name"), &Identifier::get_resource_prefix_from_type);

	ClassDB::bind_static_method("Identifier", D_METHOD("get_all_resource_types"), &Identifier::get_all_resource_types);
	ClassDB::bind_static_method("Identifier", D_METHOD("get_all_content_types"), &Identifier::get_all_content_types);

	ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("get_name"), &Identifier::get_name);
	ClassDB::bind_method(D_METHOD("get_resource_id"), &Identifier::get_resource_id);
	ClassDB::bind_method(D_METHOD("is_valid"), &Identifier::is_valid);
	ClassDB::bind_method(D_METHOD("to_string"), &Identifier::to_string);
	ClassDB::bind_method(D_METHOD("get_content_type"), &Identifier::get_content_type);
	ClassDB::bind_method(D_METHOD("get_content_prefix"), &Identifier::get_content_prefix);
	ClassDB::bind_method(D_METHOD("get_content_identifier"), &Identifier::get_content_identifier);
	ClassDB::bind_method(D_METHOD("is_texture"), &Identifier::is_texture);
}

Identifier::Identifier() {}

Identifier::~Identifier() {}

String Identifier::get_group() const {
	return group;
}

String Identifier::get_name() const {
	return name;
}

String Identifier::get_resource_id() const {
	return "dyn://" + to_string();
}

bool Identifier::is_valid() const {
	return valid;
}

String Identifier::get_content_type() const {
	String content_type = get_name().split("/")[0];
	return content_type;
}

String Identifier::get_content_prefix() const {
	String type = get_content_type();
	return get_resource_prefix_from_type(type);
}

Ref<Identifier> Identifier::get_content_identifier() const {
	String corrected_name = get_name().replace(get_content_type() + "/", "");
	return Identifier::from_values(get_group(), corrected_name);
}

bool Identifier::is_texture() const {
	String content_type = get_content_type();
	return content_type == "textures";
}

String Identifier::to_string() const {
	return String{ group } + ":" + name;
}

static inline HashMap<String, String> get_content_type_map() {
	HashMap<String, String> map;

	map["dyn"] = "dynamic";
	map["texture"] = "textures";
	map["font"] = "fonts";
	map["material"] = "materials";
	map["model"] = "models";
	map["gamemode"] = "patchdata";
	map["map"] = "maps";
	map["unit"] = "units";
	map["shader"] = "shaders";
	map["style"] = "styles";
	map["audio"] = "audio";

	return map;
}

String Identifier::get_content_type_from_resouce(String _name) {
	const static HashMap<String, String> content_type_map = get_content_type_map();

	if (!_name.contains("://")) {
		return "";
	}

	String prefix = _name.split("://")[0];
	if (content_type_map.has(prefix)) {
		return String{ content_type_map[prefix] };
	}

	return "";
}

String Identifier::get_resource_prefix_from_type(String _name) {
	const static HashMap<String, String> content_type_map = get_content_type_map();

	for (const auto &[key, value] : content_type_map) {
		if (value == _name) {
			String prefix{ key };
			return prefix + "://";
		}
	}

	return "dyn://";
}

TypedArray<String> Identifier::get_all_resource_types() {
	const static HashMap<String, String> content_type_map = get_content_type_map();

	TypedArray<String> types;
	for (const auto &[key, value] : content_type_map) {
		types.push_back(value);
	}

	return types;
}

TypedArray<String> Identifier::get_all_content_types() {
	const static HashMap<String, String> content_type_map = get_content_type_map();

	TypedArray<String> types;
	for (const auto &[key, value] : content_type_map) {
		types.push_back(key);
	}
	return types;
}

Ref<Identifier> Identifier::from_string(String _id_string) {
	String group = "openchamp";
	String name = _id_string;

	int colon = _id_string.find(":");
	if (colon != -1) {
		group = _id_string.substr(0, colon);
		name = _id_string.substr(colon + 1);
	}

	return Identifier::from_values(group, name);
}

Ref<Identifier> Identifier::from_values(String _group, String _name) {
	if (_group == "") {
		_group = "openchamp";
	}

	Ref<Identifier> id{ memnew(Identifier) };
	id->group = _group;
	id->name = _name;

	if (_name == "") {
		return nullptr;
	}

	id->valid = true;

	return id;
}

Ref<Identifier> Identifier::for_resource(String _resource_path) {
	String content_type = get_content_type_from_resouce(_resource_path);
	if (content_type == "") {
		UtilityFunctions::print("Failed to get content type from resource: " + _resource_path);
		return nullptr;
	}
	String prefix = get_resource_prefix_from_type(content_type);

	Ref<Identifier> id = Identifier::from_string(_resource_path.replace(prefix, ""));
	if (id == nullptr) {
		return nullptr;
	}

	if (content_type != "dynamic") {
		id->name = content_type + "/" + id->name;
	}

	return id;
}
