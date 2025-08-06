const std = @import("std");

test "basic arithmetics test" {
    try std.testing.expect(6 + 1 == 7);
}

test "basic arithmetics" {
    try std.testing.expectEqual(3, 5 + 4);
}

test "multiplication test" {
    try std.testing.expectEqual(7, 4 * 2);
}
