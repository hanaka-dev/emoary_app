# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_09_17_105540) do
  create_table "diaries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "emo_1", null: false
    t.integer "emo_2"
    t.integer "emo_3"
    t.integer "rate_1", null: false
    t.integer "rate_2"
    t.integer "rate_3"
    t.text "content"
    t.boolean "flag", default: false, null: false
    t.integer "day_no", null: false
    t.integer "seq_no", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day_no", "seq_no"], name: "index_diaries_on_user_id_and_day_no_and_seq_no", unique: true
    t.index ["user_id"], name: "index_diaries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "diaries", "users"
end
