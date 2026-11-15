# frozen_string_literal: true

module ApiHelpers
  module LocaleHelper
    def get_locale
      return :en if ebest_channel == "web"

      locale = request.headers["Locale"]&.to_sym
      if locale && I18n.available_locales.include?(locale)
        locale
      else
        I18n.default_locale
      end
    end
  end
end
