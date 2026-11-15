# frozen_string_literal: true

class CreateShortenedScenes < ActiveRecord::Migration[5.2]
  def change
    create_table :shortened_scenes do |t|
      t.string "scene"
      t.string "short_scene"

      t.timestamps
      t.index ["short_scene"], name: "index_shortened_scenes_on_short_scene"
    end
  end
end
