const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    const root_src = b.path("src/main.zig");

    const exe = b.addExecutable(.{
        .name = "powershell",
        .root_source_file = root_src,
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const win_step = b.step("release", "Build a release");
    inline for (&.{ .x86, .x86_64 }) |arch| {
        createReleaseCompile(b, win_step, arch, root_src);
    }
    const installscript = b.addInstallFile(.{ .path = "src/install.sh" }, "install.sh");
    win_step.dependOn(&installscript.step);
}

fn createReleaseCompile(b: *std.Build, step: *std.Build.Step, comptime arch: std.Target.Cpu.Arch, root_src: std.Build.LazyPath) void {
    const exe = b.addExecutable(.{
        .name = "powershell",
        .root_source_file = root_src,
        .target = b.resolveTargetQuery(.{
            .os_tag = .windows,
            .cpu_arch = arch,
            .cpu_model = .baseline,
        }),
        .single_threaded = true,
        .optimize = .ReleaseSmall,
    });
    const install = b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = @tagName(arch) } } });
    step.dependOn(&install.step);
}
