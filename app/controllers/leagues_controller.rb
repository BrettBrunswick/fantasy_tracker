class LeaguesController < ApplicationController
  before_action :require_login

  def index
    @leagues = League.includes(:seasons).order(:name)
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons.order(year: :desc)
    @lifetime_records = @league.lifetime_records.includes(:manager).ordered_by_wins
  end

  def lifetime_records
    @league = League.find(params[:id])
    @seasons = @league.seasons.order(:year)
    @lifetime_records = @league.lifetime_records.includes(:manager).ordered_by_win_percentage
  end

  def head_to_head
    @league = League.find(params[:id])
    @head_to_head_records = @league.head_to_head_records
      .includes(:manager, :opponent_manager)
      .order(regular_season_wins: :desc)
  end
end
