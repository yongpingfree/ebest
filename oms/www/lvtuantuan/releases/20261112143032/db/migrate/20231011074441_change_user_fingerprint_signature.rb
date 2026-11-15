# frozen_string_literal: true

class ChangeUserFingerprintSignature < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :fingerprint_signature
    add_column :users, :fingerprint_signatures, :string, comment: "指纹签名", array: true, default: []
  end
end
