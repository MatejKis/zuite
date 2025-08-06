const tester = @import("tester.zig");
const std = @import("std");
const nameSpace = 60;

/// Converts a result to a string
/// self:       The result to convert
/// allocator:  The allocator to use for the returned string
/// return:     The result as a string
pub fn resultToString(self: *const tester.Result, allocator: std.mem.Allocator) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    var writer = output.writer();

    try getDivider(&writer);
    try getHeader(self, &writer);

    if (std.mem.eql(u8, self.expected, "true")) {
        return output.toOwnedSlice();
    }

    try writer.print("|", .{});
    for (2..(nameSpace + 6 + 13)) |_| {
        try writer.print("-", .{});
    }
    try writer.print("|\n", .{});

    try getOutput(self, &writer);

    return output.toOwnedSlice();
}

/// Writes a divider to the writer
/// writer:   The writer to write to
/// return:   An error if one occurs
pub fn getDivider(writer: *std.ArrayList(u8).Writer) !void {
    for (0..(nameSpace + 6 + 13)) |_| {
        try writer.print("=", .{});
    }
    try writer.print("\n", .{});
}

/// Writes the header of a result to the writer
/// self:     The result to write the header for
/// writer:   The writer to write to
/// return:   An error if one occurs
fn getHeader(self: *const tester.Result, writer: *std.ArrayList(u8).Writer) !void {
    const passed = if (self.passed) "\x1b[32mPassed\x1b[0m" else "\x1b[31mFailed\x1b[0m";
    const nameLength = self.name.len;

    if (nameLength > nameSpace) {
        try writer.print("| Name: {s}... ", .{self.name[0..(nameSpace - 3)]});
    } else {
        try writer.print("| Name: {s} ", .{self.name});
        for (0..(nameSpace - nameLength)) |_| {
            try writer.print(" ", .{});
        }
    }

    try writer.print("| {s} |\n", .{passed});
}

/// Writes the output of a result to the writer
/// self:     The result to write the output for
/// writer:   The writer to write to
/// return:   An error if one occurs
fn getOutput(self: *const tester.Result, writer: *std.ArrayList(u8).Writer) !void {
    const resultSpace = nameSpace / 2;
    const expectedSpace = resultSpace + 3 - 4;
    const foundSpace = resultSpace - 3;

    if (self.expected.len > expectedSpace) {
        try writer.print("| Expected: {s}...", .{self.expected[0..(expectedSpace - 3)]});
    } else {
        try writer.print("| Expected: {s}", .{self.expected});
        for (0..(expectedSpace - self.expected.len)) |_| {
            try writer.print(" ", .{});
        }
    }

    if (self.found.len > foundSpace) {
        try writer.print("| Found: {s}...", .{self.found[0..(foundSpace - 3)]});
    } else {
        try writer.print("| Found: {s}", .{self.found});
        for (0..(foundSpace - self.found.len)) |_| {
            try writer.print(" ", .{});
        }
    }

    try writer.print(" |\n", .{});
}

/// Writes the name of a file to the writer
/// file:     The file to write the name of
/// writer:   The writer to write to
/// return:   An error if one occurs
pub fn writeFileName(file: *[]const u8, writer: *std.ArrayList(u8).Writer) !void {
    try getDivider(writer);
    const fileSlice = file.*;
    const length = fileSlice.len;
    
    try writer.print("| \x1b[33m", .{});

    if (length > nameSpace) {
        const args = .{fileSlice[0..(nameSpace-3)]};
        try writer.print("File: {s}...", args);
    } else {
        const args = .{fileSlice};
        try writer.print("File: {s}", args);

        for (0..(nameSpace + 9 - length)) |_| {
            try writer.print(" ", .{});
        }
    }

    try writer.print(" \x1b[0m|\n", .{});
}

