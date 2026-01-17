# == Schema Information
#
# Table name: matchups
#
#  id                :bigint           not null, primary key
#  matchup_type      :integer          default("regular_season")
#  team_1_score      :decimal(10, 2)
#  team_2_score      :decimal(10, 2)
#  week              :integer
#  yahoo_matchup_key :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  season_id         :bigint           not null
#  team_1_id         :bigint           not null
#  team_2_id         :bigint           not null
#  winner_id         :bigint
#
# Indexes
#
#  index_matchups_on_season_id           (season_id)
#  index_matchups_on_season_id_and_week  (season_id,week)
#  index_matchups_on_team_1_id           (team_1_id)
#  index_matchups_on_team_2_id           (team_2_id)
#  index_matchups_on_winner_id           (winner_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_1_id => teams.id)
#  fk_rails_...  (team_2_id => teams.id)
#  fk_rails_...  (winner_id => teams.id)
#
class Matchup < ApplicationRecord
  belongs_to :season
  belongs_to :team_1, class_name: "Team"
  belongs_to :team_2, class_name: "Team"
  belongs_to :winner, class_name: "Team", optional: true
  has_many :matchup_players, dependent: :destroy
  has_one :league, through: :season

  enum :matchup_type, {
    regular_season: 0,
    playoff: 1,
    consolation: 2,
    championship: 3
  }

  validates :week, presence: true

  scope :for_week, ->(week) { where(week: week) }
  scope :playoffs, -> { where(matchup_type: [:playoff, :championship]) }
  scope :regular_season_games, -> { where(matchup_type: :regular_season) }

  def tied?
    team_1_score.present? && team_1_score == team_2_score
  end

  def teams
    [team_1, team_2]
  end

  def opponent_for(team)
    team == team_1 ? team_2 : team_1
  end

  def score_for(team)
    team == team_1 ? team_1_score : team_2_score
  end
end
