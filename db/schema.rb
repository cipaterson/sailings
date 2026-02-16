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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_031654) do
  create_table "assignments", primary_key: ["sailing_id", "user_id"], force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "rating", default: 0
    t.integer "registration", default: 0
    t.integer "sailing_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["sailing_id"], name: "index_assignments_on_sailing_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "sailings", force: :cascade do |t|
    t.string "comments"
    t.datetime "created_at", null: false
    t.string "name"
    t.date "return_date"
    t.time "return_time"
    t.date "start_date"
    t.time "start_time"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "mobile"
    t.string "password_digest", null: false
    t.string "rating"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "assignments", "sailings"
  add_foreign_key "assignments", "users"
  add_foreign_key "sessions", "users"
end
