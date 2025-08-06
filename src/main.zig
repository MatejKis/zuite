const fr = @import("filereader.zig");
const tester = @import("tester.zig");
const out = @import("output.zig");

const std = @import("std");
const nc = @cImport({
    @cInclude("curses.h");
});

const TestingArgs = struct {
    files       :   std.ArrayList([]const u8),
    watchMode   :   bool,
    path        :   ?[]const u8,
    filter      :   ?[]const u8,
};

const TestType = enum {
    base,
    directory,
    file
};

/// The main function of the program
/// return:     An error if one occurs
pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var testingArgs = TestingArgs{
        .files = undefined,
        .watchMode = false,
        .path = null,
        .filter = null,
    };

    try parseArgs(std.heap.page_allocator, &testingArgs);

    var testType: TestType = .base;

    if (testingArgs.path) |path| {
        const stat = std.fs.cwd().statFile(path) catch |err|{
            std.debug.print("Error: could not open the file: {s}\n", .{@errorName(err)});
            return;
        };
        
        switch (stat.kind) {
            .directory => {
                testType = .directory;
            },
            .file => {
                if (std.mem.endsWith(u8, path, ".zig")) {
                    testType = .file;
                } else {
                    std.debug.print("Error: the file has to be of type '.zig': {s}\n", .{path});
                    return;
                }
            },
            else => {
                std.debug.print("Warning: Path '{s}' is not a regular file or directory.\n", .{path});
            }
        }
    }

    var result = std.ArrayList(u8).init(std.heap.page_allocator);
    var stringBuilder = result.writer();
    defer result.deinit();

    if (!testingArgs.watchMode) {
        try runTest(testType, &testingArgs, &stringBuilder);
        try writer.print("{s}\n", .{result.items});
        return;
    }

    while (true) {
        try runTest(testType, &testingArgs, &stringBuilder);
        try writer.print("\x1B[2J\x1B[H", .{});
        try writer.print("{s}\n", .{result.items});
        result.shrinkAndFree(0);
        std.time.sleep(5 * 1000 * 1000 * 1000);
    }
}

/// Runs the tests
/// testingType:  The type of testing to run
/// testingArgs:  The arguments to use for testing
/// writer:       The writer to write the output to
/// return:       An error if one occurs
fn runTest(testingType: TestType, testingArgs: *TestingArgs, writer : *std.ArrayList(u8).Writer) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
   
    if (testingType == .file) {
        var process = try tester.spawnChildProcess(allocator, testingArgs.path.?);
        try tester.runTestForAFile(allocator, writer, &testingArgs.path.?, &process);
        try out.getDivider(writer);
        return;
    }
    
    var processes = std.StringHashMap(std.process.Child).init(allocator);
    defer {
        var it = processes.valueIterator();
        while (it.next()) |process| {
            _ = process.kill() catch {};
            _ = process.wait() catch {}; 
        }
        processes.deinit();
    }

    const testPath = if (testingType == .base) "." else testingArgs.path.?;
    testingArgs.files = try fr.getTestFiles(allocator, testPath, testingArgs.filter);

    for (testingArgs.files.items) |file| {
        const process = try tester.spawnChildProcess(allocator, file);
        try processes.put(file, process);
    }

    var iterator = processes.iterator();

    while (iterator.next()) |pair| {
        try tester.runTestForAFile(allocator, writer, pair.key_ptr, pair.value_ptr);
    }
    
    try out.getDivider(writer);
}


// Parses the arguments and sets the testing arguments
//  args:           The arguments to parse
//  testingArgs:    The arguments to set
fn parseArgs(allocator: std.mem.Allocator, testingArgs : *TestingArgs) !void {

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.skip();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-w") or std.mem.eql(u8, arg, "--watch")){
            testingArgs.watchMode = true; 
        } else if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--path")) { 
            testingArgs.path = args.next();
        } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--filter")) { 
            testingArgs.filter = args.next(); 
        } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--filter")) { 

        } else {
           std.debug.print("Unknown flag: {s}\n", .{arg});
        }
    }
}
