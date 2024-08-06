#pragma once

#include "base_include.hpp"

#include "godot_cpp/classes/resource_format_loader.hpp"

namespace godot {

class GDE_EXPORT DynmaicPrefixHandler : public ResourceFormatLoader {
	GDCLASS(DynmaicPrefixHandler, ResourceFormatLoader)
private:
    Variant load_texture_from_path(String fixed_path) const;
    Variant load_font_from_path(String fixed_path) const;
    Variant load_json_from_path(String fixed_path) const;

	static Ref<DynmaicPrefixHandler> _DynmaicPrefixHandlerSingleton;
protected:
	static void _bind_methods();

public:
	static Ref<DynmaicPrefixHandler> get_singleton() { 
		if (_DynmaicPrefixHandlerSingleton.is_null()) {
			_DynmaicPrefixHandlerSingleton.instantiate();
		}

		return _DynmaicPrefixHandlerSingleton;
	}

	static void destory_singleton() {
		if (_DynmaicPrefixHandlerSingleton.is_valid()) {
			_DynmaicPrefixHandlerSingleton.unref();
		}
	}

	DynmaicPrefixHandler();
	virtual bool _recognize_path(const String &p_path, const StringName &p_type) const override;
	virtual Variant _load(const String &p_path, const String &p_original_path, bool p_use_sub_threads, int32_t p_cache_mode) const override;
	virtual Error _rename_dependencies(const String &p_path, const Dictionary &p_renames) const override;
};

}