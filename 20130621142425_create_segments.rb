class CreateSegments < ActiveRecord::Migration
  def self.up
    create_table :segments do |t|
      t.integer :flightline_id, :null => false, :options =>
        "CONSTRAINT fk_segment_flightlines REFERENCES flightlines(id)"
      t.integer :segnum, :null => false
      t.text :segmentinfo

      t.timestamps
    end
    execute "alter table segments
               add constraint fk_segment_flightlines
               foreign key  (flightline_id) references flightlines(id)"
    add_index :segments, :flightline_id
  end

  def self.down
    drop_table :segments
  end
end
