extends SceneTree

func _initialize() -> void:
    if not ClassDB.class_exists("GDXLoader"):
        push_error("GDXLoader was not registered")
        quit(1)
        return
    var loader = ClassDB.instantiate("GDXLoader")
    if loader.get_version() != "GDX-Loader 0.1.0 / Godot 4.8":
        push_error("GDXLoader version mismatch")
        quit(2)
        return
    print("GDX_LOADER_SMOKE_OK: ", loader.get_version())
    quit(0)
