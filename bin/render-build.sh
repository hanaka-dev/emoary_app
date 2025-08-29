#!/usr/bin/env bash
#exit on error
set -o errexit
bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
# ユーザーのデータを貯めるならこっち
# bundle exec rails db:migrate
# ユーザーデータのリセットをありにするならこっち
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:migrate:reset
