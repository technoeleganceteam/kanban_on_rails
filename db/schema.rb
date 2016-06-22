# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160622125505) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authentications", force: :cascade do |t|
    t.string   "provider",                null: false
    t.string   "uid",                     null: false
    t.string   "token"
    t.integer  "user_id"
    t.string   "secret"
    t.jsonb    "meta",       default: {}
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", using: :btree
  add_index "authentications", ["user_id"], name: "index_authentications_on_user_id", using: :btree

  create_table "boards", force: :cascade do |t|
    t.boolean  "public"
    t.string   "tags",          default: [],               array: true
    t.string   "name"
    t.integer  "column_width",  default: 200, null: false
    t.integer  "column_height", default: 600, null: false
    t.jsonb    "meta",          default: {}
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "columns", force: :cascade do |t|
    t.integer  "max_issues_count"
    t.integer  "column_order"
    t.string   "tags",             default: [],                 array: true
    t.string   "name",                             null: false
    t.integer  "project_id"
    t.jsonb    "meta",             default: {}
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "board_id"
    t.boolean  "backlog",          default: false, null: false
  end

  add_index "columns", ["board_id"], name: "index_columns_on_board_id", using: :btree
  add_index "columns", ["project_id"], name: "index_columns_on_project_id", using: :btree

  create_table "feedbacks", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "email",      null: false
    t.text     "content",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "issue_to_section_connections", force: :cascade do |t|
    t.integer  "issue_order"
    t.integer  "column_id"
    t.integer  "project_id"
    t.integer  "issue_id"
    t.integer  "section_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "board_id"
  end

  add_index "issue_to_section_connections", ["board_id"], name: "index_issue_to_section_connections_on_board_id", using: :btree
  add_index "issue_to_section_connections", ["column_id"], name: "index_issue_to_section_connections_on_column_id", using: :btree
  add_index "issue_to_section_connections", ["issue_id"], name: "index_issue_to_section_connections_on_issue_id", using: :btree
  add_index "issue_to_section_connections", ["project_id"], name: "index_issue_to_section_connections_on_project_id", using: :btree
  add_index "issue_to_section_connections", ["section_id"], name: "index_issue_to_section_connections_on_section_id", using: :btree

  create_table "issues", force: :cascade do |t|
    t.string   "title",                        null: false
    t.integer  "issue_order", default: 1,      null: false
    t.text     "body"
    t.string   "tags",        default: [],                  array: true
    t.integer  "project_id"
    t.jsonb    "meta",        default: {}
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "state",       default: "open", null: false
  end

  add_index "issues", ["project_id"], name: "index_issues_on_project_id", using: :btree
  add_index "issues", ["state"], name: "index_issues_on_state", using: :btree

  create_table "project_to_board_connections", force: :cascade do |t|
    t.integer  "board_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "project_to_board_connections", ["board_id"], name: "index_project_to_board_connections_on_board_id", using: :btree
  add_index "project_to_board_connections", ["project_id"], name: "index_project_to_board_connections_on_project_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",                        null: false
    t.integer  "issues_count",  default: 0,   null: false
    t.integer  "column_width",  default: 200, null: false
    t.integer  "column_height", default: 600, null: false
    t.jsonb    "meta",          default: {}
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "sections", force: :cascade do |t|
    t.string   "name",                          null: false
    t.integer  "section_order"
    t.boolean  "include_all",   default: false
    t.string   "tags",          default: [],                 array: true
    t.integer  "project_id"
    t.jsonb    "meta",          default: {}
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "board_id"
  end

  add_index "sections", ["board_id"], name: "index_sections_on_board_id", using: :btree
  add_index "sections", ["project_id"], name: "index_sections_on_project_id", using: :btree

  create_table "user_requests", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "content"
    t.integer  "likes_count", default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "user_requests", ["user_id"], name: "index_user_requests_on_user_id", using: :btree

  create_table "user_to_board_connections", force: :cascade do |t|
    t.string   "role"
    t.integer  "board_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_to_board_connections", ["board_id"], name: "index_user_to_board_connections_on_board_id", using: :btree
  add_index "user_to_board_connections", ["user_id"], name: "index_user_to_board_connections_on_user_id", using: :btree

  create_table "user_to_issue_connections", force: :cascade do |t|
    t.string   "role"
    t.integer  "user_id"
    t.integer  "issue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_to_issue_connections", ["issue_id"], name: "index_user_to_issue_connections_on_issue_id", using: :btree
  add_index "user_to_issue_connections", ["user_id"], name: "index_user_to_issue_connections_on_user_id", using: :btree

  create_table "user_to_project_connections", force: :cascade do |t|
    t.string   "role"
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_to_project_connections", ["project_id"], name: "index_user_to_project_connections_on_project_id", using: :btree
  add_index "user_to_project_connections", ["user_id"], name: "index_user_to_project_connections_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "locale",                 default: "en", null: false
    t.string   "name",                                  null: false
    t.string   "avatar_url"
    t.string   "time_zone"
    t.jsonb    "meta",                   default: {}
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
