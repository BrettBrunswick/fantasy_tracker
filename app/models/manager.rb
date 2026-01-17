class Manager < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :seasons, through: :teams
  has_many :leagues, -> { distinct }, through: :seasons
  has_many :lifetime_records, dependent: :destroy
  has_many :head_to_head_records, dependent: :destroy

  validates :name, presence: true
  validates :yahoo_guid, uniqueness: true, allow_nil: true
end
