const std = @import("std");

const Build = std.Build;

const major_version = 2;
const minor_version = 21;
const micro_version = 0;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const freetype_dep = b.dependency("freetype", .{
        .target = target,
        .optimize = optimize,
    });
    const harfbuzz_dep = b.dependency("harfbuzz", .{
        .target = target,
        .optimize = optimize,
        .enable_freetype = true,
    });
    const harfbuzz_lib = harfbuzz_dep.artifact("harfbuzz");

    const use_system_sdl2 = b.option(bool, "use_system_sdl2", "Build with system SDL2") orelse true;

    const lib = b.addStaticLibrary(.{
        .name = "SDL2_ttf",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(getInstallRelativePath(b, harfbuzz_lib, "include/harfbuzz"));
    lib.defineCMacro("TTF_USE_HARFBUZZ", "1");
    lib.defineCMacro("BUILD_SDL", "1");
    lib.defineCMacro("SDL_BUILD_MAJOR_VERSION", std.fmt.comptimePrint("{}", .{major_version}));
    lib.defineCMacro("SDL_BUILD_MINOR_VERSION", std.fmt.comptimePrint("{}", .{minor_version}));
    lib.defineCMacro("SDL_BUILD_MICRO_VERSION", std.fmt.comptimePrint("{}", .{micro_version}));
    lib.addCSourceFile(.{
        .file = .{ .path = "SDL_ttf.c" },
        .flags = &.{},
    });
    lib.linkLibC();
    if (use_system_sdl2) {
        lib.linkSystemLibrary("sdl2");
    } else {
        @panic("TODO");
    }
    lib.linkLibrary(freetype_dep.artifact("freetype"));
    lib.linkLibrary(harfbuzz_lib);
    lib.installHeader("SDL_ttf.h", "SDL2/SDL_ttf.h");
    b.installArtifact(lib);
}

fn getInstallRelativePath(b: *Build, other: *Build.Step.Compile, to: []const u8) Build.LazyPath {
    const generated = b.allocator.create(Build.GeneratedFile) catch @panic("OOM");
    generated.step = &other.step;
    generated.path = b.pathJoin(&.{ other.step.owner.install_path, to });
    return .{ .generated = generated };
}
