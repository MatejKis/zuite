const std = @import("std");
const regex = @import("regex");
const out = @import("output.zig");

pub const Result = struct {
    passed: bool,
    name: []const u8,
    expected: []const u8,
    found: []const u8,
    
    pub fn deinit(self: *const Result, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.found);
        allocator.free(self.expected);
    }
};

// Spawn the processes
// Store them together with the file names
// Run tests for process output of each file 

/// Spawns a child process to run the tests in a file
/// allocator:  The allocator to use for the process
/// fileName:   The name of the file to run the tests in
/// return:     The child process
pub fn spawnChildProcess(allocator: std.mem.Allocator, fileName: []const u8) !std.process.Child {
    var process = std.process.Child.init(&.{"zig", "test", fileName}, allocator);
    process.stdout_behavior = .Pipe;
    process.stderr_behavior = .Pipe;

    try process.spawn();

    return process;
}

fn testFile(allocator: std.mem.Allocator, process: *std.process.Child) !std.ArrayList(u8) {
    const stdoutOutput = try process.stdout.?.reader().readAllAlloc(allocator, 1024 * 4);
    defer allocator.free(stdoutOutput);
    const stderrOutput = try process.stderr.?.reader().readAllAlloc(allocator, 1024 * 4);
    defer allocator.free(stderrOutput);

    var combined = std.ArrayList(u8).init(allocator);

    try combined.appendSlice(stdoutOutput);
    try combined.appendSlice(stderrOutput);
    
    //std.debug.print("Output: {s}\n", .{combined.items});

    return combined;
}

/// Runs the tests for a file and writes the output to the writer
/// allocator:  The allocator to use for the test results
/// writer:     The writer to write the output to
/// file:       The file to run the tests for
/// process:    The process to run the tests in
/// return:     An error if one occurs
pub fn runTestForAFile(allocator: std.mem.Allocator, writer: *std.ArrayList(u8).Writer, file: *[]const u8, process: *std.process.Child) !void {
    const testResults = try getTestResults(allocator, process);
    defer testResults.deinit();
    try out.writeFileName(file, writer);

    for (testResults.items) |result| {    
        const resultStr = try out.resultToString(&result, allocator);
        defer allocator.free(resultStr);
        try writer.print("{s}", .{resultStr});
        result.deinit(allocator);
    }
}

// Gets the test results from a file
//  allocator:  The allocator to use for the returned list
//  file:       The file to get the test results from
//  return:     The test results from the file
pub fn getTestResults(allocator: std.mem.Allocator, process: *std.process.Child) !std.ArrayList(Result) {
    var test_output_list = try testFile(allocator, process);
    defer test_output_list.deinit();

    var testOutput = std.mem.tokenizeScalar(u8, test_output_list.items, '\n');

    var testPattern = try regex.Regex.compile(
        allocator,
        "\\d+/\\d+ [^\\.]+\\.test\\.([^\\.]+?)\\.\\.\\.(.*)",
    );
    defer testPattern.deinit();

    var expectedPattern = try regex.Regex.compile(
        allocator,
        "expected ([^,]+), found ([^ ]+)",
    );
    defer expectedPattern.deinit();

    var tests = std.ArrayList(Result).init(allocator);
    
    while (testOutput.next()) |line| {

        if (try testPattern.captures(line)) |match| {
            //std.debug.print("Found a match: {s}\n", .{line}); // DEBUG
            const testName = match.sliceAt(1).?;
            const testResult = match.sliceAt(2).?;

            var result = Result {
                .passed = if (std.mem.eql(u8, testResult, "OK")) true else false,
                .name = try allocator.dupe(u8, testName),
                .expected = try allocator.dupe(u8, "true"),
                .found = try allocator.dupe(u8, "false"),
            };

            if (!std.mem.startsWith(u8, testResult, "expected")) {
                try tests.append(result);
                continue;
            }

            if (try expectedPattern.captures(testResult)) |expectedMatch| {
                result.expected = try allocator.dupe(u8, expectedMatch.sliceAt(1).?);
                result.found = try allocator.dupe(u8, expectedMatch.sliceAt(2).?);
            }

            try tests.append(result);
        }
    }
    
    return tests;
}
