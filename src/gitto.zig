const std = @import("std");

const Client = std.http.Client;
const Headers = std.http.Client.Request.Headers;

pub const Gitto = struct {
    allocator: std.mem.Allocator,

    client: Client,
    headers: Headers,

    location: *const [22]u8 = "https://api.github.com",

    pub fn init(allocator: std.mem.Allocator, token: []const u8) !Gitto {
        const client = Client{ .allocator = allocator };

        const headers: Headers = .{
            .authorization = .{
                .override = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token}),
            },
            .accept_encoding = .{
                .override = "application/vnd.github+json",
            },
            .content_type = .{
                .override = "application/json",
            },
        };

        return Gitto{
            .allocator = allocator,
            .client = client,
            .headers = headers,
        };
    }

    pub fn deinit(self: *Gitto) void {
        self.allocator.free(self.headers.authorization.override);
        self.client.deinit();
    }

    pub fn octocat(self: *Gitto, response: *std.ArrayList(u8)) !std.http.Status {
        const status = try self.client.fetch(.{
            .method = std.http.Method.GET,
            .location = .{ .url = self.location ++ "/octocat" },
            .headers = self.headers,
            .response_storage = .{ .dynamic = response },
        });

        return status.status;
    }

    pub fn create_ref(
        self: *Gitto,
        owner: []const u8,
        repo: []const u8,
        ref: []const u8,
        sha: []const u8,
        response: *std.ArrayList(u8),
    ) !std.http.Status {
        const location = try std.fmt.allocPrint(
            self.allocator,
            "{s}/repos/{s}/{s}/git/refs",
            .{ self.location, owner, repo },
        );

        defer self.allocator.free(location);
        var payload = std.ArrayList(u8).init(self.allocator);
        defer payload.deinit();

        try std.json.stringify(.{
            .owner = owner,
            .repo = repo,
            .ref = ref,
            .sha = sha,
        }, .{}, payload.writer());

        const status = try self.client.fetch(.{
            .method = std.http.Method.POST,
            .location = .{ .url = location },
            .headers = self.headers,
            .payload = payload.items,
            .response_storage = .{
                .dynamic = response,
            },
        });

        return status.status;
    }

    pub fn delete_ref(
        self: *Gitto,
        owner: []const u8,
        repo: []const u8,
        ref: []const u8,
    ) !std.http.Status {
        const location = try std.fmt.allocPrint(
            self.allocator,
            "{s}/repos/{s}/{s}/git/{s}",
            .{ self.location, owner, repo, ref },
        );

        defer self.allocator.free(location);

        const status = try self.client.fetch(.{
            .method = std.http.Method.DELETE,
            .location = .{ .url = location },
            .headers = self.headers,
        });

        return status.status;
    }
};
