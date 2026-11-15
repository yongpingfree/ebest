# frozen_string_literal: true

class MagicBean::ExternalLink < ApplicationRecord
  # concerns

  # scope

  # constants

  # attr related macros

  # association macros

  # validation macros
  validates_presence_of :name, :link
  validates_format_of :link, with: URI::regexp(%w(http https))

  # callbacks

  # other macros

  # instance methods

  def mini_program_path
    ""
  end

  def app_path
    { type: "externalLink", params: { path: link } }.to_json
  end
  # class methods

  # private methods
end
