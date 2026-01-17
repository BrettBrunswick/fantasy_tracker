class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :yahoo_uid, uniqueness: true, allow_nil: true

  encrypts :access_token, :refresh_token

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end
end
