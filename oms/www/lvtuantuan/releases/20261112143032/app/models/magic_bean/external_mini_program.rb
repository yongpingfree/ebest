# frozen_string_literal: true

module MagicBean
  class ExternalMiniProgram < ApplicationRecord
    # constants

    # concerns

    # attr related macros
    enum env_version: { release: 0, develop: 1, trial: 2 }

    # association macros

    # validation macros
    validates :name, presence: true
    validates :origin_id, presence: true
    validates :path, presence: true
    validates :app_id, presence: true
    validates :env_version, presence: true

    # callbacks
    before_save :strip_fields

    # other macros

    # scopes

    # class methods

    # instance methods
    def mini_program_path
      {
        appId: app_id,
        path: path,
        envVersion: env_version
      }.to_json
    end

    def app_path
      {
        type: "miniProgram",
        params: {
          origin_id: origin_id,
          path: path,
          miniprogram_type: env_version_before_type_cast
        }
      }.to_json
    end

    private

    def strip_fields
      self.origin_id = origin_id.strip
      self.app_id = app_id.strip
      self.path = path.strip
    end
  end
end
