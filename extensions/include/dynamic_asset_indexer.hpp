#pragma once

#include "base_include.hpp"
#include "godot_cpp/classes/mutex.hpp"
#include "godot_cpp/core/mutex_lock.hpp"

#include "identifier.hpp"

namespace godot {

class GDE_EXPORT DynamicAssetIndexer : public RefCounted {
	GDCLASS(DynamicAssetIndexer, RefCounted)

private:
    HashMap<String, String> asset_map;
	bool files_indexed = false;
	
	Ref<godot::Mutex> index_mutex = nullptr;

	static Ref<DynamicAssetIndexer> _AssetIndexerSingleton;

protected:
	static void _bind_methods();

public:
	static Ref<DynamicAssetIndexer> get_singleton() { 
		if (_AssetIndexerSingleton.is_null()) {
			_AssetIndexerSingleton.instantiate();
		}

		return _AssetIndexerSingleton;
	}

	static void destory_singleton() {
		if (_AssetIndexerSingleton.is_valid()) {
			_AssetIndexerSingleton.unref();
		}
	}

	DynamicAssetIndexer();
	~DynamicAssetIndexer();
	
	void index_files();
	void re_index_files();
	String get_asset_path(Ref<Identifier> asset_id);
	TypedArray<String> get_resource_path(String raw_resource_path);

	void dump_asset_map();
	Variant get_asset_map();
};

} //namespace godot
