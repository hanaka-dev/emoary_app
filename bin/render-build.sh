#!/usr/bin/env bash
#exit on error
set -o errexit
bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
# ユーザーのデータを貯めるならこっち
bundle exec rails db:migrate
# デモアカウントと公式22枚（無ければ自動生成。既に22枚あれば日記はスキップ）
bundle exec rails demo:ensure
# ユーザーデータのリセットをありにするならこっち
# DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:migrate:reset
