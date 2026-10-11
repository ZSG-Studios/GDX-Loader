#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {
class GDXLoader : public RefCounted {
    GDCLASS(GDXLoader, RefCounted)
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("get_version"), &GDXLoader::get_version);
    }
public:
    String get_version() const { return "GDX-Loader 0.1.0 / Godot 4.8"; }
};

void initialize_gdx(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) ClassDB::register_class<GDXLoader>();
}
void uninitialize_gdx(ModuleInitializationLevel) {}
}

extern "C" {
GDExtensionBool GDE_EXPORT gdx_loader_init(
        GDExtensionInterfaceGetProcAddress get_proc_address,
        GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
    godot::GDExtensionBinding::InitObject init(get_proc_address, library, initialization);
    init.register_initializer(godot::initialize_gdx);
    init.register_terminator(godot::uninitialize_gdx);
    init.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
}
