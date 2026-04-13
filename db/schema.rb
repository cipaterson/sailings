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

ActiveRecord::Schema[8.1].define(version: 2026_04_13_071829) do
  create_table "maintenance_tasks", force: :cascade do |t|
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "date_fixed"
    t.datetime "date_reported", null: false
    t.text "fixed_note"
    t.string "problem_description", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "who_fixed"
    t.string "who_reported", null: false
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.integer "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.integer "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", force: :cascade do |t|
    t.integer "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "sailing_participants", force: :cascade do |t|
    t.integer "attended"
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
    t.string "sailing_type"
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

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "sailing_participants", "sailings"
  add_foreign_key "sailing_participants", "users"
  add_foreign_key "sessions", "users"
end
