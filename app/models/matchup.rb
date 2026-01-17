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
