# frozen_string_literal: true

module ApplicationHelper
  def active_nav?(*paths)
    paths.any? { |path| current_page?(path) } ? "active" : ""
  end

  def rich_text_render(str)
    str.gsub(/<video\s/, "<video-view\s").gsub(/<\/video>/, "</video-view>").html_safe
  end
end
