# frozen_string_literal: true

module Wechat
  class SceneCode
    @@code_mapping = YAML.load(File.read("#{Rails.root}/config/wechat_scene_code.yml"))

    def self.info(code)
      @@code_mapping[code] || "未记录"
    end
  end
end
