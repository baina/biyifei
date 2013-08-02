class CreatePrikeys < ActiveRecord::Migration
  def self.up
    create_table :prikeys do |t|
      t.string :name, :null => false
      t.integer :hashid_date
      t.text :hashvalue_flts

      t.timestamps
    end
    add_index :prikeys, :name
    add_index :prikeys, :hashid_date
  end

  def self.down
    drop_table :prikeys
  end
end