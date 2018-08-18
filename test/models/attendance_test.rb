require 'test_helper'

class AttendanceTest < ActiveSupport::TestCase
  test "create_attendance" do
    game = games(:one)
    user = users(:user_tom)
    assert_equal 0, Attendance.count
    Attendance.find_or_create_by(game: game, user: user)
    assert_equal 1, Attendance.count
    Attendance.find_or_create_by(game: game, user: user)
    assert_equal 1, Attendance.count
  end
end
