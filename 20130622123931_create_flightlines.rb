class CreateFlightlines < ActiveRecord::Migration
  def self.up
    create_table :flightlines do |t|
      t.integer :prikey_id, :null => false, :options =>
        "CONSTRAINT fk_flightline_prikeys REFERENCES prikeys(id)"
      t.string :fltcombin, :null => false
      t.integer :traveltype, :null => false
      
      t.timestamps
    end
    execute "alter table flightlines
               add constraint fk_flightline_prikeys
               foreign key  (prikey_id) references prikeys(id)"
    add_index :flightlines, :prikey_id
  end

  def self.down
    drop_table :flightlines
  end
end