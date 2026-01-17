class Season < ApplicationRecord
  belongs_to :league
  has_many :teams, dependent: :destroy
  has_many :managers, through: :teams
  has_many :matchups, dependent: :destroy
  has_many :standings, dependent: :destroy

  validates :year, presence: true, uniqueness: { scope: :league_id }
  validates :yahoo_league_key, presence: true

  scope :ordered, -> { order(year: :desc) }
end
