# frozen_string_literal: true

namespace :demo do
  desc "デモユーザーと公式22枚が無ければ作る（既に22枚あれば日記は触らない）。Render のビルドから呼ぶ想定"
  task ensure: :environment do
    DemoAccountSeed.ensure!(force_rebuild: false)
  end

  desc "公式22枚を必ず作り直す（demo_seed の葉だけ削除して再生成）。手動メンテ用"
  task rebuild: :environment do
    DemoAccountSeed.ensure!(force_rebuild: true)
  end
end
