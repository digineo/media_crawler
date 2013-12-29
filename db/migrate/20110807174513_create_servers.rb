class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.string :name
      t.string :addresses
      t.string :state, :null => false, :default => 'pending'
      t.datetime \
        :checked_at,
        :files_updated_at,
        :metadata_updated_at
      t.timestamps :null => false
    end
    
    change_table :servers do |t|
      t.index :state
      t.index :checked_at
      t.index :files_updated_at
      t.index :metadata_updated_at
    end
  end

  def self.down
    drop_table :servers
  end
end
