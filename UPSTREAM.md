# Source provenance

GDX-Loader is a fork of [godotengine/godot-cpp](https://github.com/godotengine/godot-cpp),
based on commit `b051e694cf493d417f5aa945c656cb77ae9011a9`.
Upstream MIT notices and `LICENSE.md` are retained. The `godot` namespace and
`godot_cpp` include paths remain intact for source compatibility.

The current API and interface JSON were dumped directly from the official
Windows x64 Godot 4.8-dev7 editor, `4.8.dev7.official.c971f93e7`:

```text
Godot_v4.8-dev7_win64_console.exe --headless --dump-extension-api --dump-gdextension-interface-json
```

Release: https://github.com/godotengine/godot-builds/releases/tag/4.8-dev7

Windows ZIP SHA256, matched against the release asset digest before extraction:
`560a08a239421b89e6c7532930bc78714fda12ef5cf10bc9586531c7c1a64ac2`.

GDX additions are the native Xmake graph, incremental binding preparation,
loader registration and the runtime smoke test. The profile parser includes
`OS` because the upstream core uses it even when classes are filtered.

Legacy upstream build metadata and older API snapshots are still present.
Automatic approval review rejected their removal with `blocked by policy`;
the cleanup was not retried or bypassed. The Xmake graph never reads those
older API files or delegates compilation to SCons, CMake or Make.
