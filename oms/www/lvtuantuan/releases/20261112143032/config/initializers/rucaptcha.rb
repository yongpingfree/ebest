# frozen_string_literal: true

RuCaptcha.configure do
  self.length = 4
  self.expires_in = 5.minutes
end
