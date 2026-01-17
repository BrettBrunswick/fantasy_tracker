# == Schema Information
#
# Table name: standings
#
#  id             :bigint           not null, primary key
#  losses         :integer          default(0)
#  points_against :decimal(10, 2)   default(0.0)
#  points_for     :decimal(10, 2)   default(0.0)
#  rank           :integer
#  ties           :integer          default(0)
#  wins           :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  season_id      :bigint           not null
#  team_id        :bigint           not null
#
# Indexes
#
#  index_standings_on_season_id              (season_id)
#  index_standings_on_season_id_and_team_id  (season_id,team_id) UNIQUE
#  index_standings_on_team_id                (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_id => teams.id)
#
class Standing < ApplicationRecord
  belongs_to :season
  belongs_to :team
  has_one :manager, through: :team
  has_one :league, through: :season

  validates :team_id, uniqueness: { scope: :season_id }

  scope :ordered_by_rank, -> { order(rank: :asc) }
  scope :ordered_by_wins, -> { order(wins: :desc, points_for: :desc) }

  def record_string
    ties.positive? ? "#{wins}-#{losses}-#{ties}" : "#{wins}-#{losses}"
  end

  def win_percentage
    total = wins + losses + ties
    return 0.0 if total.zero?
    (wins.to_f + (ties.to_f / 2)) / total
  end
end
