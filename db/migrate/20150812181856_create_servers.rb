class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.string :address, null: false
      t.datetime :files_updated_at
      t.timestamps null: false
    end
  end
end
