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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110807174859) do

  create_table "resources", :force => true do |t|
    t.integer  "server_id",                                    :null => false
    t.string   "path",                                         :null => false
    t.integer  "filesize",     :limit => 8
    t.boolean  "indexed",                   :default => false, :null => false
    t.text     "metadata"
    t.datetime "last_seen_at"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "resources", ["server_id", "last_seen_at"], :name => "index_resources_on_server_id_and_last_seen_at"
  add_index "resources", ["server_id", "path"], :name => "index_resources_on_server_id_and_path"

  create_table "servers", :force => true do |t|
    t.string   "name"
    t.string   "uri_ftp"
    t.string   "uri_http"
    t.string   "uri_samba"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
