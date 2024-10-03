### Gitto

This is my attempt at learning Zig and writing something useful. Any PRs are
welcome and highly appreciated.

### Usage

Add Gitto to your `build.zig.zon`

```zig
    // ...
    .dependencies = .{
        .gitto = .{
            .url = "https://github.com/o0th/gitto/archive/refs/tags/{{version}}.tar.gz",
            .hash = "{{multihash}}",
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
