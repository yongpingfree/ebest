class CreateSignInHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :sign_in_histories do |t|

      t.belongs_to :sign_in_activity
      t.belongs_to :user
      t.date :sign_in_date

      t.timestamps
    end

    add_index :sign_in_histories, [:sign_in_activity_id, :user_id, :sign_in_date], name: "index_sign_in_histories_on_user_and_activity_and_sign_in_date"
  end
end
