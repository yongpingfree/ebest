# frozen_string_literal: true

class AddAusMiniProgramOpenIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :aus_mp_open_id, :string, comment: "EBEST PTY LTD 主体小程序 Open ID"
    add_index :users, :aus_mp_open_id, unique: true
    add_column :users, :aus_mp_session_key, :string, comment: "EBEST PTY LTD 主体小程序 session key"
  end
end
