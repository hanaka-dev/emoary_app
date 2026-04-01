# frozen_string_literal: true

# 本番では環境変数で上書きしてください:
#   DEMO_ACCOUNT_EMAIL / DEMO_ACCOUNT_PASSWORD
email = ENV.fetch("DEMO_ACCOUNT_EMAIL", "demo@emoary.example").downcase.strip
password = ENV.fetch("DEMO_ACCOUNT_PASSWORD", "demoemoarydemo")

user = User.find_or_initialize_by(email: email)
user.assign_attributes(
  name: "Demo",
  password: password,
  password_confirmation: password,
  activated: true,
  activated_at: Time.current,
  demo_account: true,
  timezone: "Asia/Tokyo"
)
user.save!

# 公式 22 枚だけ入れ替え（デモ中に増えた demo_seed=false の日記は seed では消さない）
user.diaries.where(demo_seed: true).delete_all

zone = user.timezone_for_diaries
start_date = Date.new(2024, 6, 1)

22.times do |i|
  day = start_date + i.days
  Time.use_zone(zone) do
    t = Time.zone.local(day.year, day.month, day.day, 10, 0, 0)
    user.diaries.create!(
      emo_1: (i % 8) + 1,
      emo_2: nil,
      emo_3: nil,
      rate_1: 100,
      rate_2: nil,
      rate_3: nil,
      content: "Demo leaf #{i + 1}",
      flag: true,
      day_no: i + 1,
      seq_no: 1,
      demo_seed: true,
      created_at: t,
      updated_at: t
    )
  end
end

Rails.logger.info "Demo user: #{email} (password from ENV or default) — #{user.diaries.where(demo_seed: true).count} seed diaries"
