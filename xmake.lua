set_project("GDX-Loader")
set_version("0.1.0")
set_xmakever("3.1.1")
set_languages("c++17")
set_allowedplats("windows", "linux", "macosx", "android", "iphoneos", "wasm")
set_allowedmodes("debug", "release", "releasedbg")
set_policy("build.ccache", false)
add_rules("mode.debug", "mode.release", "mode.releasedbg")

option("precision")
    set_default("single")
    set_values("single", "double")
    set_showmenu(true)
option_end()
option("api_target")
    set_default("template_debug")
    set_values("template_debug", "template_release", "editor")
    set_showmenu(true)
option_end()
for _, name in ipairs({"threads", "deprecated", "hot_reload", "loader"}) do
    option(name)
        set_default(name ~= "hot_reload")
        set_showmenu(true)
    option_end()
end
option("build_profile")
    set_showmenu(true)
    set_description("Optional JSON class filter; all Godot 4.8 classes by default")
option_end()
option("binding_hooks")
    set_showmenu(true)
option_end()
option("api_file")
    set_default("gdextension/extension_api.json")
    set_showmenu(true)
option_end()
option("interface_file")
    set_default("gdextension/gdextension_interface.json")
    set_showmenu(true)
option_end()
option("python")
    set_default("python")
    set_showmenu(true)
option_end()
option("remote_only")
    set_default(false)
    set_showmenu(true)
    set_description("Require distcc for compile jobs; fails instead of local fallback")
option_end()

rule("gdx.extension")
    on_load(function (target)
        local plat, arch = target:plat(), target:arch()
        local valid = {
            windows = {x86=true, x64=true, arm64=true},
            linux = {i386=true, x86_64=true, armv7=true, arm64=true, riscv64=true, ppc64=true},
            macosx = {x86_64=true, arm64=true},
            android = {["armeabi-v7a"]=true, ["arm64-v8a"]=true, x86=true, x86_64=true},
            iphoneos = {arm64=true, x86_64=true},
            wasm = {wasm32=true}}
        assert(valid[plat] and valid[plat][arch], "Unsupported GDX platform/architecture: " .. plat .. "/" .. arch)
        target:add("defines", "GDEXTENSION", {public=true})
        if has_config("threads") then target:add("defines", "THREADS_ENABLED", {public=true}) end
        if has_config("hot_reload") then target:add("defines", "HOT_RELOAD_ENABLED", {public=true}) end
        if not has_config("deprecated") then target:add("defines", "DISABLE_DEPRECATED", {public=true}) end
        if get_config("precision") == "double" then target:add("defines", "REAL_T_IS_DOUBLE", {public=true}) end
        if get_config("api_target") ~= "template_release" then target:add("defines", "DEBUG_ENABLED", {public=true}) end
        if get_config("api_target") == "editor" then target:add("defines", "TOOLS_ENABLED", {public=true}) end
        local platform_defines = {
            windows={"WINDOWS_ENABLED", "NOMINMAX", "TYPED_METHOD_BIND"},
            linux={"LINUX_ENABLED", "UNIX_ENABLED"}, macosx={"MACOS_ENABLED", "UNIX_ENABLED"},
            android={"ANDROID_ENABLED", "UNIX_ENABLED"}, iphoneos={"IOS_ENABLED", "UNIX_ENABLED"},
            wasm={"WEB_ENABLED", "UNIX_ENABLED"}}
        target:add("defines", platform_defines[plat], {public=true})
        target:set("exceptions", "no-cxx")
        target:set("policy", "build.distcc.remote_only", has_config("remote_only"))
        if plat == "windows" then
            target:set("runtimes", "MD")
            target:add("cxflags", "/utf-8", "/Zc:__cplusplus", {tools={"cl", "clang_cl"}})
        else
            target:add("cxflags", "-fPIC", "-fvisibility=hidden")
            if has_config("threads") and plat == "linux" then
                target:add("syslinks", "pthread", {public=true})
            end
        end
        if plat == "wasm" then
            target:add("cxflags", "-sSIDE_MODULE=1", "-sSUPPORT_LONGJMP=wasm", {force=true})
            target:add("ldflags", "-sSIDE_MODULE=1", "-sWASM_BIGINT=1", "-sSUPPORT_LONGJMP=wasm", {force=true})
            if has_config("threads") then
                target:add("cxflags", "-pthread", {force=true})
                target:add("ldflags", "-pthread", {force=true})
            end
            if target:kind() == "shared" then target:set("extension", ".wasm") end
        end
    end)
rule_end()

target("gdx-bindings")
    set_kind("static")
    add_rules("gdx.extension")
    set_targetdir("build/lib/$(plat)/$(arch)/$(mode)")
    set_objectdir("build/obj/$(plat)/$(arch)/$(mode)/$(target)")
    on_load(function (target)
        local output = path.join(os.projectdir(), "build", "bindings", target:plat(), target:arch())
        local bits = ({x86=true, i386=true, armv7=true, ["armeabi-v7a"]=true, wasm32=true})[target:arch()] and "32" or "64"
        local args = {path.join(os.projectdir(), "tools", "generate.py"), "--output", output,
                      "--bits", bits, "--precision", get_config("precision"),
                      "--api", path.absolute(get_config("api_file")),
                      "--interface", path.absolute(get_config("interface_file"))}
        if get_config("build_profile") then table.join2(args, {"--profile", path.absolute(get_config("build_profile"))}) end
        if get_config("binding_hooks") then table.join2(args, {"--hooks", path.absolute(get_config("binding_hooks"))}) end
        os.vrunv(get_config("python"), args)
        target:add("includedirs", path.join(os.projectdir(), "include"), path.join(output, "gen", "include"), {public=true})
        target:add("files", path.join(os.projectdir(), "src", "**.cpp"), path.join(output, "gen", "src", "**.cpp"))
    end)
target_end()

if has_config("loader") then
    target("gdx-loader")
        set_kind("shared")
        set_basename("gdx_loader")
        set_prefixname("")
        add_deps("gdx-bindings")
        add_rules("gdx.extension")
        add_files("loader/*.cpp")
        set_targetdir("build/bin/$(plat)/$(arch)/$(mode)")
        set_objectdir("build/obj/$(plat)/$(arch)/$(mode)/$(target)")
    target_end()
end
