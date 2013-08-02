class CreatePrices < ActiveRecord::Migration
  def self.up
    create_table :prices do |t|
      t.integer :flightline_id, :null => false, :options =>
        "CONSTRAINT fk_price_flightlines REFERENCES flightlines(id)"
      t.integer :hashid_date, :null => false
      t.text :hashvalue_bunk
      t.text :hashvalue_price

      t.timestamps
    end
    execute "alter table prices
               add constraint fk_price_flightlines
               foreign key  (flightline_id) references flightlines(id)"
    add_index :prices, :flightline_id
    add_index :prices, :hashid_date
  end

  def self.down
    drop_table :prices
  end
end
