# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @site_config = MagicBean::SiteConfig.default_config
  end
end
