class Team < ApplicationRecord
  belongs_to :season
  belongs_to :manager
  has_one :league, through: :season
  has_many :matchups_as_team_1, class_name: "Matchup", foreign_key: :team_1_id, dependent: :destroy
  has_many :matchups_as_team_2, class_name: "Matchup", foreign_key: :team_2_id, dependent: :destroy
  has_many :matchup_players, dependent: :destroy
  has_one :standing, dependent: :destroy

  validates :name, presence: true
  validates :yahoo_team_key, uniqueness: true, allow_nil: true

  def matchups
    Matchup.where("team_1_id = ? OR team_2_id = ?", id, id)
  end
end
