const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const compile_metal_ir = b.addSystemCommand(&[_][]const u8{
        "xcrun",
        "-sdk",
        "macosx",
        "metal",
        "-c",
        "src/Shaders.metal",
        "-I",
        "include",
        "-o",
        "src/Shaders.air",
    });

    var compile_metal_lib = b.addSystemCommand(&[_][]const u8{
        "xcrun",
        "-sdk",
        "macosx",
        "metallib",
        "src/Shaders.air",
        "-o",
        "src/Shaders.metallib",
    });
    compile_metal_lib.step.dependOn(&compile_metal_ir.step);

    var install_metal_lib = b.addInstallFileWithDir(.{ .path = "src/Shaders.metallib" }, .prefix, "bin/default.metallib");
    install_metal_lib.step.dependOn(&compile_metal_lib.step);

    var clean_metal_artifacts = b.addSystemCommand(&[_][]const u8{
        "rm",
        "src/Shaders.air",
        "src/Shaders.metallib",
    });
    clean_metal_artifacts.step.dependOn(&install_metal_lib.step);

    b.getInstallStep().dependOn(&clean_metal_artifacts.step);

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("metal-starter-project", null);
    
    exe.step.dependOn(&compile_metal_lib.step); 

    exe.addCSourceFile("src/main.mm", &[_][]const u8{"-fobjc-arc"});

    // System frameworks
    exe.linkLibCpp(); 
    exe.linkFramework("Cocoa"); 
    exe.linkFramework("Metal"); 
    exe.linkFramework("MetalKit"); 
    
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
