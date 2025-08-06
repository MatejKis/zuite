const std = @import("std");
const regex = @import("regex");

/// Gets all the test files in a directory
/// allocator:  The allocator to use for the returned list
/// path:       The path to the directory to search in
/// filter:     An optional filter to apply to the file names
/// return:     A list of all the test files in the directory
pub fn getTestFiles(allocator: std.mem.Allocator, path: []const u8, filter: ?[]const u8) !std.ArrayList([]const u8) {    
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(path, .{.iterate = true});
    defer dir.close();

    var testFiles = std.ArrayList([]const u8).init(allocator);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry|{
        if (entry.kind == .directory) { 
            continue;
        }
        
        if (entry.kind != .file)
            continue;

        if (testName(filter, entry.basename)) {
            const term = try std.fs.path.join(allocator, &.{path, entry.path});
            try testFiles.append(term);
        }
    }

    return testFiles;
}

/// Checks if a file is a test file
/// filter:     An optional filter to apply to the file name
/// filename:   The name of the file to check
/// return:     True if the file is a test file, false otherwise
fn testName(filter: ?[]const u8, filename: []const u8) bool {
    if (filter) |f| {
        if (!std.mem.containsAtLeast(u8, filename, 1, f)) 
            return false;
    }

    const prefix = std.mem.startsWith(u8, filename, "t_") or std.mem.startsWith(u8, filename, "test_"); 
    const suffix = std.mem.endsWith(u8, filename, ".zig"); 

    return prefix and suffix;
}

// Finds all the tests inside a file
//  path:       Path of the file to walk through
//  allocator:  Allocator to use for different operations, the allocator is also used to allocate the individual items of the returned list
//  return:     List of the test names inside found inside the file, null if none were found
pub fn getTests(path: []const u8, allocator: std.mem.Allocator) !?std.ArrayList([]const u8) {

    const test_lines = try readAndFilterTestLines(path, allocator);
    defer {
        for (test_lines.items) |line| {
            allocator.free(line);
        }
        test_lines.deinit();
    }

    var pattern = try regex.Regex.compile(
        allocator,
        "test\\s+\"([^\"]*)\"\\s*\\{",
    );
    defer pattern.deinit();

    var tests = std.ArrayList([]const u8).init(allocator);
    errdefer tests.deinit();

    for (test_lines.items) |test_line| {
        if (try pattern.captures(test_line)) |matches| {
            const test_name = matches.sliceAt(1).?;
            try tests.append(try allocator.dupe(u8, test_name));
        }
    }

    if (tests.items.len == 0) {
        tests.deinit();
        return null;
    }

    return tests;
}

// Reads the content of a file and returns only the lines that start with "test"
//  path:       Path of the file to read
//  allocator:  Allocator to use for the returned list and its items
//  return:     An array list of all the lines that start with "test"
fn readAndFilterTestLines(path: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    const file = try std.fs.cwd().openFile(
        path,
        .{},
    );
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const file_content = try file.readToEndAlloc(arena_allocator, std.math.maxInt(usize));

    var lines_to_return = std.ArrayList([]const u8).init(allocator);
    errdefer lines_to_return.deinit();

    var iterator = std.mem.tokenizeScalar(u8, file_content, '\n');

    while (iterator.next()) |line| {
        if (std.mem.startsWith(u8, line, "test")) {
            try lines_to_return.append(try allocator.dupe(u8, line));
        }
    }

    return lines_to_return;
}
