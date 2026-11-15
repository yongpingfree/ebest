# frozen_string_literal: true
module MagicBean
  class CommwebPayment < Payment
    # concerns
    include MagicBean::CommwebPayment::PaymentConcern

    # scope

    # constants

    # attr related macros

    # association macros

    # validation macros

    # callbacks
    after_create :enqueue_check_commweb_paid_job, if: :charge_payment_type?

    # other macros

    # instance methods

    # private methods
  end
end
