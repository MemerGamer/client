#pragma once

#include "base_include.hpp"

#include "identifier.hpp"

namespace godot {

class GDE_EXPORT DataCacheManager : public RefCounted {
	GDCLASS(DataCacheManager, RefCounted)

private:
    HashMap<String, String> hashed_data_map;
	bool files_indexed = false;

	static Ref<DataCacheManager> _DataCacheManagerSingleton;

protected:
	static void _bind_methods();

public:
	static Ref<DataCacheManager> get_singleton() { 
		if (_DataCacheManagerSingleton.is_null()) {
			_DataCacheManagerSingleton.instantiate();
		}

		return _DataCacheManagerSingleton;
	}

	static void destory_singleton() {
		if (_DataCacheManagerSingleton.is_valid()) {
			_DataCacheManagerSingleton.unref();
		}
	}

	DataCacheManager();
	~DataCacheManager();
	
	void index_files();
	void re_index_files();

	String cache_file(String file_path);
	String cache_string(String str);

	bool is_cached(String hash);
	String get_cached_string(String hash);
	Ref<JSON> get_cached_json(String hash);

	void dump_hash_map();
	Variant get_hash_map();

    static String get_file_hash(String file_path);
	static String get_string_hash(String str);
};

} //namespace godot
