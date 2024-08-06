#pragma once

# include "base_include.hpp"

namespace godot {

class GDE_EXPORT Identifier : public RefCounted {
	GDCLASS(Identifier, RefCounted)

private:
	String group;
	String name;

	bool valid = false;

protected:
	static void _bind_methods();

public:
	Identifier();
	~Identifier();

	static Ref<Identifier> from_string(String _id_string);
	static Ref<Identifier> from_values(String _group, String _name);
	static Ref<Identifier> for_resource(String _resource_path);

	static String get_content_type_from_resouce(String _name);
	static String get_resource_prefix_from_type(String _name);

	static TypedArray<String> get_all_resource_types();
	static TypedArray<String> get_all_content_types();

	String get_content_type() const;
	String get_content_prefix() const;

	Ref<Identifier> get_content_identifier() const;

	String get_group() const;
	String get_name() const;
	String get_resource_id() const;

	bool is_valid() const;
	
	String to_string() const;
	bool is_texture() const;
};

} //namespace godot
