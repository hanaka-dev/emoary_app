# frozen_string_literal: true

require "test_helper"

class DiaryJournalMetadataTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @user.diaries.destroy_all
    log_in_as @user
  end

  def valid_diary_attrs
    {
      emo_1: 1,
      emo_2: nil,
      emo_3: nil,
      rate_1: 100,
      rate_2: nil,
      rate_3: nil,
      content: "first leaf"
    }
  end

  test "first diary of calendar day is flag true seq_no 1 day_no 1" do
    zone = @user.timezone_for_diaries
    travel_to Time.use_zone(zone) { Time.zone.parse("2025-06-10 12:00:00") } do
      assert_difference "Diary.count", 1 do
        post diaries_path, params: { diary: valid_diary_attrs }
      end
      assert_redirected_to home_path
      d = Diary.order(:id).last
      assert d.flag, "代表1件は flag true"
      assert_equal 1, d.day_no
      assert_equal 1, d.seq_no
    end
  end

  test "second diary same calendar day is flag false and increments seq_no" do
    zone = @user.timezone_for_diaries
    travel_to Time.use_zone(zone) { Time.zone.parse("2025-06-11 09:00:00") } do
      post diaries_path, params: { diary: valid_diary_attrs.merge(content: "one") }
      assert_response :redirect
      post diaries_path, params: { diary: valid_diary_attrs.merge(content: "two") }
      assert_response :redirect

      first = Diary.find_by!(content: "one")
      second = Diary.find_by!(content: "two")
      assert first.flag
      assert_not second.flag
      assert_equal first.day_no, second.day_no
      assert_equal 1, first.seq_no
      assert_equal 2, second.seq_no
    end
  end

  test "new calendar day increments day_no and resets seq_no to 1 with flag true" do
    zone = @user.timezone_for_diaries
    travel_to Time.use_zone(zone) { Time.zone.parse("2025-06-12 15:00:00") } do
      post diaries_path, params: { diary: valid_diary_attrs.merge(content: "day1") }
    end

    travel_to Time.use_zone(zone) { Time.zone.parse("2025-06-13 08:00:00") } do
      post diaries_path, params: { diary: valid_diary_attrs.merge(content: "day2") }
    end

    d1 = Diary.find_by!(content: "day1")
    d2 = Diary.find_by!(content: "day2")
    assert d1.flag
    assert d2.flag
    assert_equal 1, d1.day_no
    assert_equal 2, d2.day_no
    assert_equal 1, d1.seq_no
    assert_equal 1, d2.seq_no
  end

  test "reconcile makes earliest created_at the only flag true when times are reordered" do
    zone = "Asia/Tokyo"
    @user.update_column(:timezone, zone)
    travel_to Time.use_zone(zone) { Time.zone.parse("2025-07-01 12:00:00") } do
      d1 = @user.diaries.create!(
        emo_1: 1, rate_1: 100, content: "a", flag: false, day_no: 1, seq_no: 1
      )
      d2 = @user.diaries.create!(
        emo_1: 2, rate_1: 100, content: "b", flag: false, day_no: 1, seq_no: 2
      )
      # あとから d2 の方が「その日で早い時刻」だった場合
      afternoon = Time.use_zone(zone) { Time.zone.parse("2025-07-01 14:00:00") }
      morning = Time.use_zone(zone) { Time.zone.parse("2025-07-01 08:00:00") }
      d1.update_columns(created_at: afternoon, updated_at: afternoon)
      d2.update_columns(created_at: morning, updated_at: morning)

      Diary.reconcile_display_flags_for_user_journal_date!(@user, Date.new(2025, 7, 1), zone)

      assert_not d1.reload.flag
      assert d2.reload.flag
    end
  end

  test "destroying flagged diary promotes next earliest to flag true" do
    zone = "Asia/Tokyo"
    @user.update_column(:timezone, zone)
    travel_to Time.use_zone(zone) { Time.zone.parse("2025-08-01 10:00:00") } do
      d1 = @user.diaries.create!(
        emo_1: 1, rate_1: 100, content: "x", flag: false, day_no: 1, seq_no: 1
      )
      d2 = @user.diaries.create!(
        emo_1: 2, rate_1: 100, content: "y", flag: false, day_no: 1, seq_no: 2
      )
      Diary.reconcile_display_flags_for_user_journal_date!(@user, Date.new(2025, 8, 1), zone)
      assert d1.reload.flag
      assert_not d2.reload.flag

      d1.destroy!

      assert d2.reload.flag
    end
  end

  test "user timezone shifts which records count as same calendar day" do
    @user.update_column(:timezone, "America/New_York")
    # UTC 2025-09-01 03:00 → 夏時間の NY では 8/31 23:00（まだ 8/31）
    utc_moment = Time.utc(2025, 9, 1, 3, 0, 0)
    travel_to utc_moment do
      post diaries_path, params: { diary: valid_diary_attrs.merge(content: "ny late aug") }
    end
    d = Diary.find_by!(content: "ny late aug")
    assert_equal Date.new(2025, 8, 31), d.created_at.in_time_zone("America/New_York").to_date
  end
end
