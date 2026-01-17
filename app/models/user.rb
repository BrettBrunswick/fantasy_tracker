# == Schema Information
#
# Table name: users
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  email            :string
#  refresh_token    :text
#  token_expires_at :datetime
#  yahoo_uid        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_users_on_email      (email) UNIQUE
#  index_users_on_yahoo_uid  (yahoo_uid) UNIQUE
#
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :yahoo_uid, uniqueness: true, allow_nil: true

  encrypts :access_token, :refresh_token

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end
end
