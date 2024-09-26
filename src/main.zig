const std = @import("std");

pub const Gitto = struct {
    allocator: std.mem.Allocator,

    client: std.http.Client,
    server_header_buffer: [4096]u8,
    authorization_header_buffer: [100]u8,

    fn init(allocator: std.mem.Allocator, token: []const u8) !Gitto {
        const client = std.http.Client{ .allocator = allocator };

        const server_header_buffer: [4096]u8 = undefined;
        var authorization_header_buffer: [100]u8 = undefined;

        _ = try std.fmt.bufPrint(
            &authorization_header_buffer,
            "Bearer {s}",
            .{token},
        );

        return Gitto{
            .allocator = allocator,
            .client = client,
            .server_header_buffer = server_header_buffer,
            .authorization_header_buffer = authorization_header_buffer,
        };
    }

    fn deinit(self: *Gitto) void {
        self.client.deinit();
    }

    fn octocat(self: *Gitto, response: *std.ArrayList(u8)) !std.http.Status {
        const status = try self.client.fetch(.{
            .method = std.http.Method.GET,
            .location = .{ .url = "https://api.github.com/octocat" },
            .server_header_buffer = &self.server_header_buffer,
            .response_storage = .{ .dynamic = response },
        });

        return status.status;
    }

    fn create_tag(self: *Gitto, response: *std.ArrayList(u8)) !std.http.Status {
        var payload = std.ArrayList(u8).init(self.allocator);
        defer payload.deinit();

        try std.json.stringify(.{
            .owner = "o0th",
            .repo = "gitto",
            .ref = "refs/tags/v0.0.0",
            .sha = "82cd2492ad06183b1fff18c46607ecc3a65a7f31",
        }, .{}, payload.writer());

        const status = try self.client.fetch(.{
            .method = std.http.Method.POST,
            .location = .{
                .url = "https://api.github.com/repos/o0th/gitto/git/refs",
            },
            .server_header_buffer = &self.server_header_buffer,
            .headers = .{
                .authorization = .{
                    .override = &self.authorization_header_buffer,
                },
                .accept_encoding = .{
                    .override = "application/vnd.github+json",
                },
                .content_type = .{
                    .override = "application/json",
                },
            },
            .response_storage = .{
                .dynamic = response,
            },
            .payload = payload.items,
        });

        return status.status;
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

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    const octocat = try gitto.create_tag(&response);
    try std.fmt.format(stdout, "Status: {}\n", .{octocat});
    try std.fmt.format(stdout, "Response: {s}\n", .{response.items});

    return 0;
}
