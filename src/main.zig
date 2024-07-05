const std = @import("std");

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

    var server_headers: [4096]u8 = undefined;
    const uri = try std.Uri.parse("https://api.github.com/octocat");

    var authorization_header_buf: [64]u8 = undefined;
    const authorization_header = try std.fmt.bufPrint(&authorization_header_buf, "Bearer {s}", .{
        GITHUB_TOKEN,
    });

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var request = try client.open(.GET, uri, .{
        .server_header_buffer = &server_headers,
    });

    defer request.deinit();

    request.headers.authorization = .{
        .override = authorization_header,
    };

    try request.send();
    try request.wait();

    var body: [1024]u8 = undefined;
    const size = try request.reader().readAll(&body);

    try std.fmt.format(stdout, "{s}\n", .{body});
    try std.fmt.format(stdout, "{}\n", .{size});
    return 0;
}
