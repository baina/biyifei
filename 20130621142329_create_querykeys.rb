class CreateQuerykeys < ActiveRecord::Migration
  def self.up
    create_table :querykeys do |t|
      t.string :name, :null => false
      t.string :carriercode

      t.timestamps
    end
    add_index :querykeys, :name
  end

  def self.down
    drop_table :querykeys
  end
end
