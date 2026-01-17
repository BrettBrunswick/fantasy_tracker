class MatchupPlayer < ApplicationRecord
  belongs_to :matchup
  belongs_to :team

  validates :player_name, presence: true
  validates :yahoo_player_key, uniqueness: { scope: [:matchup_id, :team_id] }, allow_nil: true

  scope :by_position, ->(position) { where(position: position) }
  scope :ordered_by_points, -> { order(points: :desc) }
end
