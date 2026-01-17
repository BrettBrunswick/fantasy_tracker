class SeasonsController < ApplicationController
  before_action :require_login
  before_action :set_league
  before_action :set_season

  def show
    @teams = @season.teams.includes(:manager).order("managers.name")
    @standings = @season.standings.includes(team: :manager).order(rank: :asc)
    @matchups = @season.matchups.includes(:team_1, :team_2).order(week: :desc).limit(20)
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_season
    @season = @league.seasons.find(params[:id])
  end
end
