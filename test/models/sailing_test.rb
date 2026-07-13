require "test_helper"

class SailingTest < ActiveSupport::TestCase
  # Validations

  test "valid with purpose and sailing_type" do
    sailing = Sailing.new(purpose: "Harbour cruise", sailing_type: "Sail")
    assert sailing.valid?
  end

  test "invalid without purpose" do
    sailing = Sailing.new
    assert_not sailing.valid?
    assert_includes sailing.errors[:purpose], "can't be blank"
  end

  test "valid sailing_type values are accepted" do
    Sailing::SAILING_TYPES.each do |type|
      sailing = Sailing.new(purpose: "Test", sailing_type: type)
      assert sailing.valid?, "Expected #{type} to be valid"
    end
  end

  test "invalid sailing_type raises ArgumentError" do
    assert_raises(ArgumentError) { Sailing.new(purpose: "Test", sailing_type: "Joyride") }
  end

  test "blank sailing_type is not allowed" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "")
    assert_not sailing.valid?
    assert_includes sailing.errors[:sailing_type], "can't be blank"
  end

  # combine_datetime_fields callback

  test "combine_datetime_fields sets departs_at from date and time" do
    sailing = Sailing.new(purpose: "Test")
    sailing.departs_date = "2026-06-01"
    sailing.departs_time = "09:00"
    sailing.valid?
    assert_equal Time.zone.parse("2026-06-01 09:00"), sailing.departs_at
  end

  test "combine_datetime_fields sets returns_at from date and time" do
    sailing = Sailing.new(purpose: "Test")
    sailing.returns_date = "2026-06-01"
    sailing.returns_time = "17:00"
    sailing.valid?
    assert_equal Time.zone.parse("2026-06-01 17:00"), sailing.returns_at
  end

  test "combine_datetime_fields leaves departs_at unchanged when departs_date is blank" do
    sailing = Sailing.new(purpose: "Test", departs_at: Time.zone.parse("2026-06-01 09:00"))
    sailing.departs_date = ""
    sailing.valid?
    assert_equal Time.zone.parse("2026-06-01 09:00"), sailing.departs_at
  end

  test "combine_datetime_fields handles missing time gracefully" do
    sailing = Sailing.new(purpose: "Test")
    sailing.departs_date = "2026-06-01"
    sailing.departs_time = ""
    sailing.valid?
    assert_not_nil sailing.departs_at
  end

  # Voyage date validations

  test "invalid when a departure has no return" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail",
                          departs_at: Time.zone.parse("2026-06-01 09:00"))
    assert_not sailing.valid?
    assert_includes sailing.errors[:base], "A return date and time is required when there is a departure"
  end

  test "invalid when the return is before the departure" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail")
    sailing.departs_date = "2026-06-02"
    sailing.departs_time = "09:00"
    sailing.returns_date = "2026-06-01"
    sailing.returns_time = "09:00"
    assert_not sailing.valid?
    assert_includes sailing.errors[:base], "Return date and time must be after the departure date and time"
  end

  test "invalid when the return equals the departure" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail")
    sailing.departs_date = "2026-06-01"
    sailing.departs_time = "09:00"
    sailing.returns_date = "2026-06-01"
    sailing.returns_time = "09:00"
    assert_not sailing.valid?
    assert_includes sailing.errors[:base], "Return date and time must be after the departure date and time"
  end

  test "valid when the return is after the departure" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail")
    sailing.departs_date = "2026-09-02" # a free date, so the overlap check doesn't fire
    sailing.departs_time = "09:00"
    sailing.returns_date = "2026-09-02"
    sailing.returns_time = "17:00"
    assert sailing.valid?
  end

  test "valid when neither departure nor return is set" do
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail")
    assert sailing.valid?
  end

  # Overlapping voyages

  def overlapping_new_sailing
    Sailing.new(purpose: "Clash", sailing_type: "Sail",
                departs_at: Time.zone.parse("2026-06-01 12:00"),
                returns_at: Time.zone.parse("2026-06-01 18:00"))
  end

  test "overlapping_sailings finds a voyage whose window intersects" do
    assert_includes overlapping_new_sailing.overlapping_sailings, sailings(:voyage)
  end

  test "overlapping_sailings ignores back-to-back voyages" do
    sailing = Sailing.new(purpose: "After", sailing_type: "Sail",
                          departs_at: Time.zone.parse("2026-06-01 17:00"),
                          returns_at: Time.zone.parse("2026-06-01 20:00"))
    assert_empty sailing.overlapping_sailings
  end

  test "overlapping_sailings ignores voyages on other days" do
    sailing = Sailing.new(purpose: "Elsewhere", sailing_type: "Sail",
                          departs_at: Time.zone.parse("2026-06-05 09:00"),
                          returns_at: Time.zone.parse("2026-06-05 17:00"))
    assert_empty sailing.overlapping_sailings
  end

  test "overlapping_sailings excludes the voyage itself" do
    assert_empty sailings(:voyage).overlapping_sailings
  end

  test "overlapping_sailings is empty without both datetimes" do
    sailing = Sailing.new(purpose: "Partial", sailing_type: "Sail",
                          departs_at: Time.zone.parse("2026-06-01 09:00"))
    assert_empty sailing.overlapping_sailings
  end

  test "an unconfirmed overlap is invalid" do
    sailing = overlapping_new_sailing
    assert_not sailing.valid?
    assert sailing.errors[:base].any? { |m| m.include?("overlap") }
  end

  test "a confirmed overlap is valid" do
    sailing = overlapping_new_sailing
    sailing.confirm_overlap = "1"
    assert sailing.valid?
  end

  test "a non-overlapping voyage is valid without confirmation" do
    sailing = Sailing.new(purpose: "Clear", sailing_type: "Sail",
                          departs_at: Time.zone.parse("2026-06-05 09:00"),
                          returns_at: Time.zone.parse("2026-06-05 17:00"))
    assert sailing.valid?
  end

  # auto_set_status callback

  def create_scheduled_sailing
    sailing = Sailing.new(purpose: "Test", sailing_type: "Sail", status: "draft")
    sailing.departs_date = "2026-09-01" # a date no fixture occupies, to avoid overlap
    sailing.departs_time = "09:00"
    sailing.returns_date = "2026-09-01"
    sailing.returns_time = "17:00"
    sailing.save!
    sailing
  end

  test "new sailing with a departure date is promoted to scheduled" do
    sailing = create_scheduled_sailing
    assert_equal "scheduled", sailing.status
    assert_not_nil sailing.departs_at
  end

  test "setting an existing sailing to draft clears its dates" do
    sailing = create_scheduled_sailing
    sailing.update!(status: "draft")
    assert_equal "draft", sailing.status
    assert_nil sailing.departs_at
    assert_nil sailing.returns_at
  end

  test "setting draft clears dates submitted in the same update" do
    sailing = create_scheduled_sailing
    sailing.status = "draft"
    sailing.departs_date = "2026-09-01"
    sailing.departs_time = "10:00"
    sailing.save!
    assert_equal "draft", sailing.status
    assert_nil sailing.departs_at
  end

  test "updating a scheduled sailing without touching status keeps its dates" do
    sailing = create_scheduled_sailing
    sailing.update!(purpose: "Renamed")
    assert_equal "scheduled", sailing.status
    assert_not_nil sailing.departs_at
  end

  # Date/time readers

  test "departs_date returns nil when departs_at is nil" do
    sailing = Sailing.new
    assert_nil sailing.departs_date
  end

  test "departs_time returns nil when departs_at is nil" do
    sailing = Sailing.new
    assert_nil sailing.departs_time
  end

  test "departs_date returns the date portion of departs_at" do
    sailing = sailings(:voyage)
    assert_equal Date.new(2026, 6, 1), sailing.departs_date
  end

  test "departs_time returns HH:MM string" do
    sailing = sailings(:voyage)
    assert_equal "09:00", sailing.departs_time
  end

  test "returns_date returns nil when returns_at is nil" do
    sailing = sailings(:no_return)
    assert_nil sailing.returns_date
  end

  # voyage_dates

  test "voyage_dates returns empty string when departs_at is nil" do
    sailing = sailings(:no_dates)
    assert_equal "", sailing.voyage_dates
  end

  test "voyage_dates with same-day return omits return date" do
    sailing = sailings(:voyage)
    result = sailing.voyage_dates
    assert_includes result, "01 Jun 2026"
    assert_includes result, "09:00"
    assert_includes result, "17:00"
    assert_equal 1, result.scan("01 Jun 2026").length, "Date should appear only once for same-day sailing"
  end

  test "voyage_dates with multi-day return includes both dates" do
    sailing = sailings(:multiday)
    result = sailing.voyage_dates
    assert_includes result, "10 Jul 2026"
    assert_includes result, "12 Jul 2026"
  end

  test "voyage_dates with no return time shows only departure" do
    sailing = sailings(:no_return)
    result = sailing.voyage_dates
    assert_includes result, "01 Aug 2026"
    assert_not_includes result, "to"
  end
end
