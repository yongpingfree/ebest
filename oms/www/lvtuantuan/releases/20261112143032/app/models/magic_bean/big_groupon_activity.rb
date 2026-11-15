# frozen_string_literal: true
module MagicBean
  class BigGrouponActivity < GrouponActivity
    # scope

    # constants

    # attr related macros

    # association macros

    # validation macros

    # callbacks
    after_create :generate_groupon

    # other macros

    private

    def generate_groupon
      MagicBean::Groupon.creating_by_big_groupon_activity(self)
    end
  end
end
