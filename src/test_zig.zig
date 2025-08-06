const std = @import("std");

test "always true" {
    try std.testing.expect(true);
}

test "always false" {
    try std.testing.expect(false);
}

test "fail" {
    try std.testing.expect(false);
}
