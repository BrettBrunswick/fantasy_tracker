class HeadToHeadRecord < ApplicationRecord
  belongs_to :manager
  belongs_to :opponent_manager, class_name: "Manager"
  belongs_to :league

  validates :manager_id, uniqueness: { scope: [:opponent_manager_id, :league_id] }

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

  def overall_record
    ties = regular_season_ties
    wins = total_wins
    losses = total_losses
    ties.positive? ? "#{wins}-#{losses}-#{ties}" : "#{wins}-#{losses}"
  end
end
