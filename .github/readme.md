### Gitto

This is my attempt at learning Zig and writing something useful. Any PRs are
welcome and highly appreciated.

### Usage

Add Gitto to your `build.zig.zon`

```zig
    // ...
    .dependencies = .{
        .gitto = .{
            .url = "https://github.com/o0th/gitto/archive/refs/tags/v0.0.0.tar.gz",
            .hash = "1220ad24ac92f72978282f0602b5330245995a649471a655ff26b8ce8096f72c30fd",
        },
    },
    // ...
```

Add Gitto to your `build.zig` before `b.installArtifact(exe)`

```zig
    // ...
    const gitto = b.dependency("gitto", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("gitto", gitto.module("gitto"));
    // ...
```
