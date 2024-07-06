const std = @import("std");

pub const Gitto = struct {
    allocator: std.mem.Allocator,
    token: []const u8,

    client: std.http.Client,
    authorization_header: []const u8,

    fn init(allocator: std.mem.Allocator, token: []const u8) !Gitto {
        const client = std.http.Client{ .allocator = allocator };

        var authorization_header_buf: [64]u8 = undefined;
        const authorization_header = try std.fmt.bufPrint(
            &authorization_header_buf,
            "Bearer {s}",
            .{
                token,
            },
        );

        return Gitto{
            .allocator = allocator,
            .token = token,
            .client = client,
            .authorization_header = authorization_header,
        };
    }

    fn deinit(self: *Gitto) void {
        self.client.deinit();
    }

    fn octocat(self: *Gitto) ![]u8 {
        const uri = try std.Uri.parse("https://api.github.com/octocat");

        var server_headers: [4096]u8 = undefined;
        var request = try self.client.open(.GET, uri, .{
            .server_header_buffer = &server_headers,
        });

        defer request.deinit();

        request.headers.authorization = .{
            .override = self.authorization_header,
        };

        try request.send();
        try request.wait();

        var body: [1024]u8 = undefined;
        _ = try request.reader().readAll(&body);

        return &body;
    }
};

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

    const octocat = try gitto.octocat();
    try std.fmt.format(stdout, "{s}\n", .{octocat});

    return 0;
}
