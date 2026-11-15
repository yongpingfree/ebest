# frozen_string_literal: true

# ref: https://github.com/heartcombo/devise/blob/master/lib/devise/models/trackable.rb
module UserTrackableConcern
  extend ActiveSupport::Concern

  def assign_tracked_fields(ip_address)
    old_current_time, new_current_time = self.current_visit_at, Time.current
    self.last_visit_at    = old_current_time || new_current_time
    self.current_visit_at = new_current_time

    old_current_ip, new_current_ip = self.current_visit_ip, ip_address
    self.last_visit_ip    = old_current_ip || new_current_ip
    self.current_visit_ip = new_current_ip
  end

  def update_tracked_fields(ip_address)
    # We have to check if the user is already persisted before running
    # `save` here because invalid users can be saved if we don't.
    return if new_record?

    assign_tracked_fields(ip_address)
    save(validate: false)
  end
end
