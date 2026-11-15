# frozen_string_literal: true

class AddFingerprintSignatureToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :fingerprint_signature, :text, comment: "指纹签名"
    add_index :users, :fingerprint_signature, unique: true
  end
end
