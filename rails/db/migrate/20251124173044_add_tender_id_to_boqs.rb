class AddTenderIdToBoqs < ActiveRecord::Migration[7.2]
  def change
    add_reference :boqs, :tender, foreign_key: true
  end
end
