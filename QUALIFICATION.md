# Initial qualification - 2026-10-11

| Boundary | Result |
| --- | --- |
| Official editor acquisition | 4.8-dev7 Windows x64 ZIP digest matched GitHub release digest; executable reports `4.8.dev7.official.c971f93e7` |
| Binding generation | Official 4.8 API/interface dump; all-class generation succeeds; small smoke profile compiles |
| Windows x64 | Native Xmake debug compile + LLVM link succeeded; official editor loaded `GDXLoader`; GDScript version call printed `GDX_LOADER_SMOKE_OK` |
| Android arm64-v8a | Native Xmake debug compile + link succeeded with installed NDK 30.0.16248370 / API 37; no device load or export check |
| Web wasm32 | Native Xmake debug compile + link succeeded with activated Emscripten 6.0.12; no browser load or export check |
| Linux x86_64 | Configuration is implemented; local WSL reported input/output errors accessing `/mnt/c/GDX Workspace`; compilation not verified |
| macOS / iOS | Platform configuration implemented; no Apple build, signing, export or runtime check |
| Other architectures | Declared platform/architecture mappings; not compiled or runtime-qualified |
| Full binding library | All-class generation only; compilation was limited to the smoke profile |
| Distributed compilation | Not verified for GDX; existing server reservation belongs to EGP CI; shared configuration preserved |
| Repository cleanup | Automatic approval review rejected cleanup with `blocked by policy`; legacy files remain; no retry or bypass |

Small local checks used two compile jobs to keep the workstation responsive.
The smoke profile retains the classes required by upstream binding core code;
it is not evidence for Superpos, Box2D, Box3D, rollback, recovery or managed
runtime integration. No source from those projects is copied into this fork.

Canonical output root is `build/`; no parallel complete output snapshots were
created. Failed release intermediates from an interrupted configuration are
still under that root, and cleanup has not been retried.
