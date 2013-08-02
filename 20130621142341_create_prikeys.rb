class CreatePrikeys < ActiveRecord::Migration
  def self.up
    create_table :prikeys do |t|
      t.string :name
      t.integer :querykey_id, :null => false, :options =>
        "CONSTRAINT fk_prikey_querykeys REFERENCES querykeys(id)"
      t.integer :hashid_date, :null => false
      t.string :hashvalue_flts

      t.timestamps
    end
    execute "alter table prikeys
               add constraint fk_prikey_querykeys
               foreign key  (querykey_id) references querykeys(id)"
    add_index :prikeys, :name
    add_index :prikeys, :querykey_id
    add_index :prikeys, :hashid_date
  end

  def self.down
    drop_table :prikeys
  end
end
