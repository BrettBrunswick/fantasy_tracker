# == Schema Information
#
# Table name: leagues
#
#  id               :bigint           not null, primary key
#  name             :string
#  yahoo_league_key :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class League < ApplicationRecord
  has_many :seasons, dependent: :destroy
  has_many :teams, through: :seasons
  has_many :managers, -> { distinct }, through: :teams
  has_many :matchups, through: :seasons
  has_many :lifetime_records, dependent: :destroy
  has_many :head_to_head_records, dependent: :destroy

  validates :name, presence: true

  def current_season
    seasons.order(year: :desc).first
  end
end
