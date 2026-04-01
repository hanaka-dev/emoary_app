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
      emotions = random_emotion_bundle(i)
      Time.use_zone(zone) do
        t = Time.zone.local(day.year, day.month, day.day, 10, 0, 0)
        user.diaries.create!(
          **emotions,
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

  # 葉ごとに 1〜3 感情・割合が変わる「ランダムっぽさ」。シード固定でデプロイのたびに同じ並びになる。
  def self.random_emotion_bundle(index)
    rng = Random.new(20_240_601 + index * 97)
    pool = (1..8).to_a.shuffle(random: rng)
    n = rng.rand(1..3)

    if n == 1
      {
        emo_1: pool[0], emo_2: nil, emo_3: nil,
        rate_1: 100, rate_2: nil, rate_3: nil
      }
    elsif n == 2
      r1 = rng.rand(1..99)
      {
        emo_1: pool[0], emo_2: pool[1], emo_3: nil,
        rate_1: r1, rate_2: 100 - r1, rate_3: nil
      }
    else
      r1 = rng.rand(1..96)
      r2 = rng.rand(1..(99 - r1))
      r3 = 100 - r1 - r2
      {
        emo_1: pool[0], emo_2: pool[1], emo_3: pool[2],
        rate_1: r1, rate_2: r2, rate_3: r3
      }
    end
  end
  private_class_method :random_emotion_bundle
end
