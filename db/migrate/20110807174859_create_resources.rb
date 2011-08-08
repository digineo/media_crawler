class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.references :server, :null => false
      t.string :path, :null => false
      t.integer :size, :null => false
      t.text :metadata

      t.timestamps :null => false
    end
  end

  def self.down
    drop_table :resources
  end
end
