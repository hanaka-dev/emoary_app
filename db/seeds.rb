# frozen_string_literal: true

# 本番では DEMO_ACCOUNT_EMAIL / DEMO_ACCOUNT_PASSWORD を環境変数で指定してください。
# 毎回公式22枚を作り直す（従来どおり db:seed 用）
DemoAccountSeed.ensure!(force_rebuild: true)
