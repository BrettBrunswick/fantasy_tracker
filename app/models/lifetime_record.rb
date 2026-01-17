class LifetimeRecord < ApplicationRecord
  belongs_to :manager
  belongs_to :league

  validates :manager_id, uniqueness: { scope: :league_id }

  scope :ordered_by_wins, -> { order(regular_season_wins: :desc) }
  scope :ordered_by_championships, -> { order(championships_won: :desc) }

  def total_wins
    regular_season_wins + playoff_wins
  end

  def total_losses
    regular_season_losses + playoff_losses
  end

  def regular_season_record
    regular_season_ties.positive? ? "#{regular_season_wins}-#{regular_season_losses}-#{regular_season_ties}" : "#{regular_season_wins}-#{regular_season_losses}"
  end

  def playoff_record
    "#{playoff_wins}-#{playoff_losses}"
  end

  def championship_record
    "#{championships_won}-#{championships_lost}"
  end

  def win_percentage
    total = regular_season_wins + regular_season_losses + regular_season_ties
    return 0.0 if total.zero?
    (regular_season_wins.to_f + (regular_season_ties.to_f / 2)) / total
  end
end
