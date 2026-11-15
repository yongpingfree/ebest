# frozen_string_literal: true

class CreateAgeVerifications < ActiveRecord::Migration[5.2]
  def change
    create_table :age_verifications do |t|
      t.references :parent_category, foreign_key: { to_table: "categories" }
      t.string :image

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::AgeVerification.create_translation_table! title: :string, content: :string
      end

      dir.down do
        MagicBean::AgeVerification.drop_translation_table!
      end
    end
  end
end
