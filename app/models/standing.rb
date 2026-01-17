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
