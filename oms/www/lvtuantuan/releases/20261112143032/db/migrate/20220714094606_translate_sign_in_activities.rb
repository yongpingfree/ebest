# frozen_string_literal: true

class TranslateSignInActivities < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        MagicBean::SignInActivity.create_translation_table!(
          {
            title: :string
          })
      end

      dir.down do
        MagicBean::SignInActivity.drop_translation_table!
      end
    end
  end
end
