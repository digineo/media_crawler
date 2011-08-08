class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.string :name
      t.string \
        :uri_ftp,
        :uri_http,
        :uri_samba

      t.timestamps :null => false
    end
  end

  def self.down
    drop_table :servers
  end
end
