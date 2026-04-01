# frozen_string_literal: true

require "test_helper"

class DemoAccountTest < ActionDispatch::IntegrationTest
  setup do
    @demo = User.create!(
      name: "Demo",
      email: "demointegration@example.com",
      password: "password",
      password_confirmation: "password",
      activated: true,
      activated_at: Time.zone.now,
      demo_account: true,
      timezone: "Asia/Tokyo"
    )
    t = Time.zone.parse("2025-01-01 10:00:00")
    @demo.diaries.create!(
      emo_1: 1, emo_2: nil, emo_3: nil, rate_1: 100, rate_2: nil, rate_3: nil,
      content: "seed", flag: true, day_no: 1, seq_no: 1,
      demo_seed: true, created_at: t, updated_at: t
    )
    @demo.diaries.create!(
      emo_1: 2, emo_2: nil, emo_3: nil, rate_1: 100, rate_2: nil, rate_3: nil,
      content: "extra", flag: true, day_no: 2, seq_no: 1,
      demo_seed: false, created_at: t + 1.day, updated_at: t + 1.day
    )
  end

  test "demo_login signs in demo user" do
    post demo_login_path
    assert_redirected_to home_path
    assert_equal @demo.id, session[:user_id]
  end

  test "logout deletes only non-demo_seed diaries" do
    post demo_login_path
    assert_equal 2, @demo.reload.diaries.count

    delete logout_path
    follow_redirect!

    assert_equal 1, @demo.reload.diaries.count
    assert_predicate @demo.diaries.first, :demo_seed?
    assert_equal "seed", @demo.diaries.first.content
  end

  test "demo user cannot update settings" do
    log_in_as(@demo)
    patch settings_path, params: { user: { name: "Hacked" } }
    assert_redirected_to settings_path
    assert_equal "Demo", @demo.reload.name
  end

  test "demo user cannot delete account" do
    log_in_as(@demo)
    assert_no_difference "User.count" do
      delete settings_path
    end
    assert_redirected_to settings_path
    assert User.exists?(@demo.id)
  end
end
