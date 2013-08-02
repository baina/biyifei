# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130622123947) do

  create_table "flightlines", :force => true do |t|
    t.integer  "prikey_id",  :null => false
    t.string   "fltcombin",  :null => false
    t.integer  "traveltype", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "flightlines", ["prikey_id"], :name => "index_flightlines_on_prikey_id"

  create_table "prices", :force => true do |t|
    t.integer  "flightline_id",   :null => false
    t.integer  "hashid_date",     :null => false
    t.text     "hashvalue_price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prices", ["flightline_id"], :name => "index_prices_on_flightline_id"
  add_index "prices", ["hashid_date"], :name => "index_prices_on_hashid_date"

  create_table "prikeys", :force => true do |t|
    t.string   "name",           :null => false
    t.integer  "hashid_date"
    t.text     "hashvalue_flts"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prikeys", ["hashid_date"], :name => "index_prikeys_on_hashid_date"
  add_index "prikeys", ["name"], :name => "index_prikeys_on_name"

  create_table "segments", :force => true do |t|
    t.integer  "flightline_id", :null => false
    t.integer  "segnum",        :null => false
    t.text     "segmentinfo",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "segments", ["flightline_id"], :name => "index_segments_on_flightline_id"
  add_index "segments", ["segnum"], :name => "index_segments_on_segnum"

end
