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

ActiveRecord::Schema[8.1].define(version: 2026_03_11_061731) do
  create_table "sailing_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sailing_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["sailing_id", "user_id"], name: "index_sailing_participants_on_sailing_id_and_user_id", unique: true
    t.index ["sailing_id"], name: "index_sailing_participants_on_sailing_id"
    t.index ["user_id"], name: "index_sailing_participants_on_user_id"
  end

  create_table "sailings", force: :cascade do |t|
    t.text "additional_details"
    t.string "charter_address1"
    t.string "charter_address2"
    t.string "charter_city"
    t.string "charter_email_address"
    t.string "charter_full_name"
    t.string "charter_mobile"
    t.string "charter_postcode"
    t.string "charter_state"
    t.string "charter_work_phone"
    t.string "charterer"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "departs_at"
    t.string "engineer"
    t.string "ln_contact"
    t.string "master"
    t.integer "passenger_count"
    t.string "purpose"
    t.datetime "returns_at"
    t.string "status"
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
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.date "ess_expires_on"
    t.date "ess_issued_on"
    t.string "ess_qualification"
    t.string "first_name"
    t.string "home_phone"
    t.date "knots_on"
    t.string "last_name"
    t.date "marine_safety_refresher_on"
    t.date "med_expires_on"
    t.date "med_issued_on"
    t.string "med_qualification"
    t.string "membership_type"
    t.string "mobile_phone"
    t.string "occupation"
    t.string "password_digest", null: false
    t.integer "roles_mask", default: 0, null: false
    t.string "sailing_class"
    t.date "sit_date"
    t.datetime "updated_at", null: false
    t.date "wwvp_expires_on"
    t.date "wwvp_issued_on"
    t.string "wwvp_qualification"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sailing_participants", "sailings"
  add_foreign_key "sailing_participants", "users"
  add_foreign_key "sessions", "users"
end
