# == Schema Information
#
# Table name: seasons
#
#  id               :bigint           not null, primary key
#  yahoo_league_key :string
#  year             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_id        :bigint           not null
#  yahoo_game_id    :string
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
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
