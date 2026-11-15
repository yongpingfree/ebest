# frozen_string_literal: true

class TranslateMinePageActivitySettings < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::MinePageActivitySetting.create_translation_table!({
          name: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        MagicBean::MinePageActivitySetting.drop_translation_table! migrate_data: true
      end
    end

    say_with_time "初始化MinePageActivitySetting的name" do
      MagicBean::MinePageActivitySetting.reset_column_information

      MagicBean::MinePageActivitySetting.find_each do |setting|
        setting.send :set_name_i18n
        setting.save
      end
    end
  end
end
