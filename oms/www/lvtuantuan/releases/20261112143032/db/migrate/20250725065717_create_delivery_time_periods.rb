class CreateDeliveryTimePeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_time_periods do |t|

      t.belongs_to :delivery_time
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::DeliveryTimePeriod.create_translation_table! title: :string
      end

      dir.down do
        MagicBean::DeliveryTimePeriod.drop_translation_table!
      end
    end
  end
end
