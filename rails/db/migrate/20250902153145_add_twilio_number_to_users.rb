class AddTwilioNumberToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :twilio_number, :string
  end
end
