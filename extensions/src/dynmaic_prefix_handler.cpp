#include "dynmaic_prefix_handler.hpp"

#include "dynamic_asset_indexer.hpp"
#include "identifier.hpp"

#include "godot_cpp/classes/resource_loader.hpp"
#include "godot_cpp/classes/image.hpp"
#include "godot_cpp/classes/image_texture.hpp"
#include "godot_cpp/classes/font_file.hpp"
#include "godot_cpp/classes/file_access.hpp"
#include "godot_cpp/classes/json.hpp"

using namespace godot;


void DynmaicPrefixHandler::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_texture_from_path"), &DynmaicPrefixHandler::load_texture_from_path);
	ClassDB::bind_method(D_METHOD("load_font_from_path"), &DynmaicPrefixHandler::load_font_from_path);
	ClassDB::bind_method(D_METHOD("load_json_from_path"), &DynmaicPrefixHandler::load_json_from_path);
}

DynmaicPrefixHandler::DynmaicPrefixHandler() {}


bool DynmaicPrefixHandler::_recognize_path(const String &p_path, const StringName &p_type) const {
	static TypedArray<String> supported_prefixes = Identifier::get_all_content_types();
    for (int64_t i = 0; i < supported_prefixes.size(); i++){
		String prefix = supported_prefixes[i];
        if (p_path.begins_with(prefix + "://")){
            return true;
        }
    }
    
	return false;
}

Error DynmaicPrefixHandler::_rename_dependencies(const String &p_path, const Dictionary &p_renames) const{
    return OK;
}

Variant DynmaicPrefixHandler::_load(const String &p_path, const String &p_original_path, bool p_use_sub_threads, int32_t p_cache_mode) const{
    TypedArray<String> resource_stuff = DynamicAssetIndexer::get_singleton()->get_resource_path(p_path);
	if (resource_stuff.size() < 2){
		UtilityFunctions::print("Failed to get resource path for: '" + p_path + "'");
		return FAILED;
    }

	String fixed_path = resource_stuff[0];
    String content_type = resource_stuff[1];
	
    if (ResourceLoader::get_singleton()->exists(fixed_path)){
		UtilityFunctions::print("loading '"+ fixed_path + "' from the ResourceLoader.");
		auto load_result = ResourceLoader::get_singleton()->load(fixed_path);
		if (load_result != nullptr){
			return load_result;
        }else{
			UtilityFunctions::print("Failed to load resource from ResourceLoader: '" + fixed_path + "'");
			return FAILED;
        }
    }


	UtilityFunctions::print("loading '" + p_path + "' as: " + fixed_path);
    if (content_type == "textures"){
        return load_texture_from_path(fixed_path);
    }else if (content_type == "fonts"){
        return load_font_from_path(fixed_path);
    }else{
        if (fixed_path.ends_with(".json")){
            return load_json_from_path(fixed_path);
        }
    }

    return FAILED;
}


Variant DynmaicPrefixHandler::load_texture_from_path(String fixed_path) const{
	auto loaded_image = Image::load_from_file(fixed_path);
	if (loaded_image == nullptr){
		UtilityFunctions::print("Error loading image from file.");
		return FAILED;
    }
	
	auto loaded_texture = ImageTexture::create_from_image(loaded_image);
	if (loaded_texture == nullptr){
		UtilityFunctions::print("error loading dynamic texture: '" + fixed_path + "'");
		return FAILED;
    }
	
	return loaded_texture;
}


Variant DynmaicPrefixHandler::load_font_from_path(String fixed_path) const{
	Ref<FontFile> loaded_font = memnew(FontFile);
	auto err = loaded_font->load_dynamic_font(fixed_path);

	if (err != OK){
		UtilityFunctions::print("error loading dynamic font: '" + fixed_path + "'");
        return FAILED;
    }
	
	return loaded_font;
}


Variant DynmaicPrefixHandler::load_json_from_path(String fixed_path) const{
	auto file = FileAccess::open(fixed_path, FileAccess::ModeFlags::READ);
	if (file == nullptr){
		UtilityFunctions::print("error dynamic json not in file loader: '" + fixed_path + "'");
		return FAILED;
    }

	Ref<JSON> json_data = memnew(JSON);
	auto error = json_data->parse(file->get_as_text());
	file->close();

	if (error != OK){
		UtilityFunctions::print("error parsing dynamic json: '" + fixed_path + "'");
		return FAILED;
    }

	return json_data;
}

