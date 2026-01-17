# == Schema Information
#
# Table name: matchup_players
#
#  id               :bigint           not null, primary key
#  player_name      :string
#  points           :decimal(10, 2)
#  position         :string
#  yahoo_player_key :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  matchup_id       :bigint           not null
#  team_id          :bigint           not null
#
# Indexes
#
#  idx_matchup_players_unique           (matchup_id,team_id,yahoo_player_key) UNIQUE
#  index_matchup_players_on_matchup_id  (matchup_id)
#  index_matchup_players_on_team_id     (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (matchup_id => matchups.id)
#  fk_rails_...  (team_id => teams.id)
#
class MatchupPlayer < ApplicationRecord
  belongs_to :matchup
  belongs_to :team

  validates :player_name, presence: true
  validates :yahoo_player_key, uniqueness: { scope: [:matchup_id, :team_id] }, allow_nil: true

  scope :by_position, ->(position) { where(position: position) }
  scope :ordered_by_points, -> { order(points: :desc) }
end
