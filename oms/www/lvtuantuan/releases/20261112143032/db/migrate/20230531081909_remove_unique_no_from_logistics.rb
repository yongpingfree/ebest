# frozen_string_literal: true

class RemoveUniqueNoFromLogistics < ActiveRecord::Migration[5.2]
  reversible do |dir|
    dir.up do
      remove_index :logistics, :no
      add_index :logistics, :no
    end

    dir.down do
      remove_index :logistics, :no
      add_index :logistics, :no, unique: true
    end
  end
end
