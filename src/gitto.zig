const std = @import("std");

const Client = std.http.Client;
const Status = std.http.Status;
const Headers = std.http.Client.Request.Headers;
const ResponseStorage = std.http.Client.FetchOptions.ResponseStorage;

pub const Gitto = @This();

location: *const [22]u8 = "https://api.github.com",
allocator: std.mem.Allocator,

client: Client,
headers: Headers,

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

pub fn octocat(self: *Gitto, response: *std.ArrayList(u8)) !Status {
    const status = try self.client.fetch(.{
        .method = std.http.Method.GET,
        .location = .{ .url = self.location ++ "/octocat" },
        .headers = self.headers,
        .response_storage = .{ .dynamic = response },
    });

    return status.status;
}

pub const CreateRefOptions = struct {
    owner: []const u8,
    repo: []const u8,
    ref: []const u8,
    sha: []const u8,
    response: ?*std.ArrayList(u8) = null,
};

/// Creates a reference
/// https://docs.github.com/en/rest/git/refs?apiVersion=2022-11-28#create-a-reference
pub fn create_ref(self: *Gitto, options: CreateRefOptions) !Status {
    const location = try std.fmt.allocPrint(
        self.allocator,
        "{s}/repos/{s}/{s}/git/refs",
        .{ self.location, options.owner, options.repo },
    );

    defer self.allocator.free(location);
    var payload = std.ArrayList(u8).init(self.allocator);
    defer payload.deinit();

    try std.json.stringify(.{
        .owner = options.owner,
        .repo = options.repo,
        .ref = options.ref,
        .sha = options.sha,
    }, .{}, payload.writer());

    const response = try self.client.fetch(.{
        .method = std.http.Method.POST,
        .location = .{ .url = location },
        .headers = self.headers,
        .payload = payload.items,
        .response_storage = if (options.response != null) .{
            .dynamic = options.response.?,
        } else ResponseStorage.ignore,
    });

    return response.status;
}

pub const UpdateRefOptions = struct {
    owner: []const u8,
    repo: []const u8,
    ref: []const u8,
    sha: []const u8,
    force: bool = false,
    response: ?*std.ArrayList(u8) = null,
};

/// Update a reference
/// https://docs.github.com/en/rest/git/refs?apiVersion=2022-11-28#update-a-reference
pub fn update_ref(self: *Gitto, options: UpdateRefOptions) !Status {
    const location = try std.fmt.allocPrint(
        self.allocator,
        "{s}/repos/{s}/{s}/git/{s}",
        .{ self.location, options.owner, options.repo, options.ref },
    );

    defer self.allocator.free(location);

    var payload = std.ArrayList(u8).init(self.allocator);
    defer payload.deinit();

    try std.json.stringify(.{
        .sha = options.sha,
        .force = options.force,
    }, .{}, payload.writer());

    const response = try self.client.fetch(.{
        .method = std.http.Method.PATCH,
        .location = .{ .url = location },
        .headers = self.headers,
        .payload = payload.items,
        .response_storage = if (options.response != null) .{
            .dynamic = options.response.?,
        } else ResponseStorage.ignore,
    });

    return response.status;
}

pub const DeleteRefOptions = struct {
    owner: []const u8,
    repo: []const u8,
    ref: []const u8,
};

/// Delete a reference
/// https://docs.github.com/en/rest/git/refs?apiVersion=2022-11-28#delete-a-reference
pub fn delete_ref(self: *Gitto, options: DeleteRefOptions) !Status {
    const location = try std.fmt.allocPrint(
        self.allocator,
        "{s}/repos/{s}/{s}/git/{s}",
        .{ self.location, options.owner, options.repo, options.ref },
    );

    defer self.allocator.free(location);

    const response = try self.client.fetch(.{
        .method = std.http.Method.DELETE,
        .location = .{ .url = location },
        .headers = self.headers,
    });

    return response.status;
}
