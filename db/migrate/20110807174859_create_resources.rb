class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.references :server, :null => false
      t.string :path, :null => false
      t.column :filesize, 'bigint unsigned'
      t.boolean :indexed, :null => false, :default => false
      t.string :checksum
      t.text :metadata
      t.datetime :last_seen_at
      t.timestamps :null => false
    end
    
    change_table :resources do |t|
      t.index [:server_id, :path], :unique => true
      t.index [:server_id, :indexed]
      t.index [:server_id, :checksum]
      t.index [:server_id, :last_seen_at]
    end
  end

  def self.down
    drop_table :resources
  end
end
