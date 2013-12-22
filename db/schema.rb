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

ActiveRecord::Schema.define(version: 20110807174859) do

  create_table "resources", force: true do |t|
    t.integer  "server_id",                              null: false
    t.string   "path",                                   null: false
    t.integer  "filesize",     limit: 8
    t.boolean  "indexed",                default: false, null: false
    t.string   "checksum"
    t.text     "metadata"
    t.datetime "last_seen_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "resources", ["server_id", "checksum"], name: "index_resources_on_server_id_and_checksum", using: :btree
  add_index "resources", ["server_id", "indexed"], name: "index_resources_on_server_id_and_indexed", using: :btree
  add_index "resources", ["server_id", "last_seen_at"], name: "index_resources_on_server_id_and_last_seen_at", using: :btree
  add_index "resources", ["server_id", "path"], name: "index_resources_on_server_id_and_path", unique: true, using: :btree

  create_table "servers", force: true do |t|
    t.string   "name"
    t.string   "uri_ftp"
    t.string   "uri_http"
    t.string   "uri_samba"
    t.string   "state",               default: "pending", null: false
    t.datetime "checked_at"
    t.datetime "files_updated_at"
    t.datetime "metadata_updated_at"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "servers", ["checked_at"], name: "index_servers_on_checked_at", using: :btree
  add_index "servers", ["files_updated_at"], name: "index_servers_on_files_updated_at", using: :btree
  add_index "servers", ["metadata_updated_at"], name: "index_servers_on_metadata_updated_at", using: :btree
  add_index "servers", ["state"], name: "index_servers_on_state", using: :btree

end
