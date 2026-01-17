# == Schema Information
#
# Table name: managers
#
#  id         :bigint           not null, primary key
#  email      :string
#  name       :string
#  yahoo_guid :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_managers_on_yahoo_guid  (yahoo_guid) UNIQUE
#
class Manager < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :seasons, through: :teams
  has_many :leagues, -> { distinct }, through: :seasons
  has_many :lifetime_records, dependent: :destroy
  has_many :head_to_head_records, dependent: :destroy

  validates :name, presence: true
  validates :yahoo_guid, uniqueness: true, allow_nil: true
end
