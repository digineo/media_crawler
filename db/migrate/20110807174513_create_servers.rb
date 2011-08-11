class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.string :name
      t.string \
        :uri_ftp,
        :uri_http,
        :uri_samba
      t.string :state, :null => false, :default => 'pending'
      t.datetime :checked_at
      t.timestamps :null => false
    end
    
    change_table :servers do |t|
      t.index :state
      t.index :checked_at
    end
  end

  def self.down
    drop_table :servers
  end
end
