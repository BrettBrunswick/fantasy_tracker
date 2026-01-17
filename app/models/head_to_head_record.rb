# == Schema Information
#
# Table name: head_to_head_records
#
#  id                    :bigint           not null, primary key
#  current_streak        :string
#  playoff_losses        :integer          default(0)
#  playoff_wins          :integer          default(0)
#  regular_season_losses :integer          default(0)
#  regular_season_ties   :integer          default(0)
#  regular_season_wins   :integer          default(0)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  league_id             :bigint           not null
#  manager_id            :bigint           not null
#  opponent_manager_id   :bigint           not null
#
# Indexes
#
#  idx_h2h_manager_opponent_league                    (manager_id,opponent_manager_id,league_id) UNIQUE
#  index_head_to_head_records_on_league_id            (league_id)
#  index_head_to_head_records_on_manager_id           (manager_id)
#  index_head_to_head_records_on_opponent_manager_id  (opponent_manager_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#  fk_rails_...  (manager_id => managers.id)
#  fk_rails_...  (opponent_manager_id => managers.id)
#
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

  def win_percentage
    total = total_wins + total_losses + regular_season_ties
    return 0.0 if total.zero?
    (total_wins.to_f + regular_season_ties.to_f / 2) / total
  end
end
