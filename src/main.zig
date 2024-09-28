const std = @import("std");
const Gitto = @import("gitto.zig").Gitto;

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    var variables = std.process.getEnvMap(allocator) catch {
        try std.fmt.format(stderr, "Something went wrong\n", .{});
        return 1;
    };

    defer variables.deinit();

    const GITHUB_TOKEN = variables.get("GITHUB_TOKEN") orelse {
        try std.fmt.format(stderr, "GITHUB_TOKEN is missing\n", .{});
        return 1;
    };

    var gitto = try Gitto.init(allocator, GITHUB_TOKEN);
    defer gitto.deinit();

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    _ = try gitto.octocat(&response);
    try std.fmt.format(stdout, "Response: {s}\n", .{response.items});

    const create = try gitto.create_ref(
        "o0th",
        "gitto",
        "refs/tags/v0.0.0",
        "82cd2492ad06183b1fff18c46607ecc3a65a7f31",
        &response,
    );

    try std.fmt.format(stdout, "Status: {}\n", .{create});
    try std.fmt.format(stdout, "Response: {s}\n", .{response.items});

    const delete = try gitto.delete_ref("o0th", "gitto", "refs/tags/v0.0.0");

    try std.fmt.format(stdout, "Status: {}\n", .{delete});

    return 0;
}
