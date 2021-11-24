const std = @import("std");

const raylibFlags = &[_][]const u8{
    "-std=gnu99",
    "-DPLATFORM_DESKTOP",
    "-DGL_SILENCE_DEPRECATION",
    "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
};

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable("cleartouch", "src/main.zig");

    exe.addIncludeDir("raylib/include");
    exe.addLibPath("raylib/lib");

    const target = b.standardTargetOptions(.{});
    exe.setTarget(target);

    const mode = b.standardReleaseOptions();
    exe.setBuildMode(mode);

    exe.linkLibC();
    exe.addIncludeDir("./lib/raylib/src");
    exe.addIncludeDir("./lib/raylib/src/external/glfw/include");
    exe.addCSourceFile("./lib/raylib/src/rcore.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rmodels.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/raudio.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rshapes.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rtext.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rtextures.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/utils.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rglfw.c", raylibFlags);

    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("rt");
    exe.linkSystemLibrary("dl");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("X11");

    exe.install();

    // const compile_step = b.step("compile", "Compiles src/main.zig");
    // compile_step.dependOn(&exe.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

}