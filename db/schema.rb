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

ActiveRecord::Schema[8.1].define(version: 2026_07_04_024105) do
  create_table "contacts", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "contact_type"
    t.integer "contactable_id", null: false
    t.string "contactable_type", null: false
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "full_name"
    t.string "mobile"
    t.string "postcode"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "work_phone"
    t.index ["contactable_type", "contactable_id"], name: "index_contacts_on_contactable_type_and_contactable_id"
  end

  create_table "maintenance_tasks", force: :cascade do |t|
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "date_fixed"
    t.datetime "date_reported", null: false
    t.text "fixed_note"
    t.string "priority"
    t.string "problem_description", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "who_fixed"
    t.string "who_reported", null: false
  end

  create_table "sailing_participants", force: :cascade do |t|
    t.integer "attended"
    t.integer "climbing", default: 0
    t.text "comment"
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
    t.string "charter_state", default: "TBC"
    t.string "charterer"
    t.text "comments"
    t.datetime "created_at", null: false
    t.date "date_paid"
    t.datetime "departs_at"
    t.integer "deposit_cents"
    t.string "deposit_invoice"
    t.date "deposit_invoice_date"
    t.string "deposit_receipt_no"
    t.string "engineer"
    t.integer "final_amount_cents"
    t.string "final_invoice"
    t.date "invoice_date"
    t.string "ln_contact"
    t.string "master"
    t.integer "passenger_count"
    t.string "purpose"
    t.integer "quoted_cost_cents"
    t.string "receipt_no"
    t.datetime "returns_at"
    t.string "sailing_type"
    t.string "status", default: "draft"
    t.string "training"
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
    t.datetime "approved_at"
    t.date "birth_date"
    t.date "coxswain_expires_on"
    t.date "coxswain_issued_on"
    t.string "coxswain_qualification"
    t.datetime "created_at", null: false
    t.date "date_joined"
    t.integer "days_sailed"
    t.string "email_address", null: false
    t.date "ess_expires_on"
    t.date "ess_issued_on"
    t.string "ess_qualification"
    t.integer "fees_due"
    t.date "fees_paid"
    t.date "first_aid_expires_on"
    t.date "first_aid_issued_on"
    t.string "first_aid_qualification"
    t.string "first_name"
    t.date "food_handling_expires_on"
    t.date "food_handling_issued_on"
    t.string "food_handling_qualification"
    t.date "knots_on"
    t.string "last_name"
    t.date "last_sailed"
    t.date "marine_safety_refresher_on"
    t.date "med_expires_on"
    t.date "med_issued_on"
    t.string "med_qualification"
    t.string "membership_type"
    t.string "occupation"
    t.string "password_digest", null: false
    t.string "rcpt_number"
    t.integer "roles_mask", default: 0, null: false
    t.string "sailing_class"
    t.date "sit2_date"
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
