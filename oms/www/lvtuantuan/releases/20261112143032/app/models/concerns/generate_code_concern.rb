# frozen_string_literal: true

module GenerateCodeConcern
  extend ActiveSupport::Concern

  def generate_code(length = 4)
    loop do
      self.code = SecureRandom.hex(length)
      break unless self.class.exists?(code: code)
    end
  end
end
