# == Schema Information
#
# Table name: lifetime_records
#
#  id                    :bigint           not null, primary key
#  championships_lost    :integer          default(0)
#  championships_won     :integer          default(0)
#  playoff_losses        :integer          default(0)
#  playoff_wins          :integer          default(0)
#  regular_season_losses :integer          default(0)
#  regular_season_ties   :integer          default(0)
#  regular_season_wins   :integer          default(0)
#  total_points_against  :decimal(10, 2)   default(0.0)
#  total_points_for      :decimal(10, 2)   default(0.0)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  league_id             :bigint           not null
#  manager_id            :bigint           not null
#
# Indexes
#
#  index_lifetime_records_on_league_id                 (league_id)
#  index_lifetime_records_on_manager_id                (manager_id)
#  index_lifetime_records_on_manager_id_and_league_id  (manager_id,league_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#  fk_rails_...  (manager_id => managers.id)
#
class LifetimeRecord < ApplicationRecord
  belongs_to :manager
  belongs_to :league

  validates :manager_id, uniqueness: { scope: :league_id }

  scope :ordered_by_wins, -> { order(regular_season_wins: :desc) }
  scope :ordered_by_championships, -> { order(championships_won: :desc) }
  scope :ordered_by_win_percentage, -> {
    order(Arel.sql("(regular_season_wins + regular_season_ties * 0.5) / NULLIF(regular_season_wins + regular_season_losses + regular_season_ties, 0) DESC NULLS LAST"))
  }

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
