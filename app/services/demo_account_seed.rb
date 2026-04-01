# frozen_string_literal: true

# デモユーザーと公式22枚の日記を用意する。
# force_rebuild: false のとき、すでに demo_seed が22件あれば日記の作り直しはスキップ（デプロイ連打で安全）。
class DemoAccountSeed
  def self.ensure!(force_rebuild: false)
    email = ENV.fetch("DEMO_ACCOUNT_EMAIL", "demo@emoary.app").downcase.strip
    # Render の ENV は末尾改行・スペースが混ざることがあるので必ず strip
    password = ENV.fetch("DEMO_ACCOUNT_PASSWORD", "demoemoarydemo").to_s.strip

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

    seed_count = user.diaries.where(demo_seed: true).count
    if seed_count == 22 && !force_rebuild
      Rails.logger.info "DemoAccountSeed: 22 seed diaries already present, skip rebuild"
      return user
    end

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

    Rails.logger.info "DemoAccountSeed: #{email} — #{user.diaries.where(demo_seed: true).count} seed diaries"
    user
  end
end
