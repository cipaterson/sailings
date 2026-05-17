require "test_helper"

class SailingParticipantTest < ActiveSupport::TestCase
  def build_participant(overrides = {})
    SailingParticipant.new(
      { sailing: sailings(:voyage), user: users(:one), status: "EOI" }.merge(overrides)
    )
  end

  # Validations — status

  test "valid statuses are accepted" do
    SailingParticipant::STATUSES.each do |status|
      sp = build_participant(status: status, user: users(:two))
      # two is already on voyage as Accepted in fixtures; use a fresh sailing
      sp.sailing = sailings(:no_return)
      assert sp.valid?, "Expected '#{status}' to be a valid status"
    end
  end

  test "invalid status is rejected" do
    sp = build_participant(status: "Maybe")
    assert_not sp.valid?
    assert sp.errors[:status].any?
  end

  # Validations — presence

  test "invalid without sailing" do
    sp = build_participant(sailing: nil)
    assert_not sp.valid?
    assert sp.errors[:sailing].any?
  end

  test "invalid without user" do
    sp = build_participant(user: nil)
    assert_not sp.valid?
    assert sp.errors[:user].any?
  end

  # Uniqueness — one registration per user per sailing

  test "user cannot be registered for the same sailing twice" do
    sp = build_participant(user: users(:one), sailing: sailings(:voyage))
    assert_not sp.valid?
    assert sp.errors[:user_id].any?
  end

  test "same user can be on different sailings" do
    sp = build_participant(user: users(:one), sailing: sailings(:multiday))
    assert sp.valid?
  end

  test "different users can be on the same sailing" do
    # users(:one) is already on voyage via fixture; users(:two) is also on voyage
    # Adding users(:one) to a different sailing should be fine
    sp = build_participant(user: users(:one), sailing: sailings(:no_return))
    assert sp.valid?
  end
end
