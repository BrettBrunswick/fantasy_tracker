class LeaguesController < ApplicationController
  before_action :require_login

  def index
    @leagues = League.includes(:seasons).order(:name)
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons.order(year: :desc)
    @lifetime_records = @league.lifetime_records.includes(:manager).order(wins: :desc)
  end

  def lifetime_records
    @league = League.find(params[:id])
    @lifetime_records = @league.lifetime_records.includes(:manager).order(wins: :desc)
  end

  def head_to_head
    @league = League.find(params[:id])
    @head_to_head_records = @league.head_to_head_records
      .includes(:manager, :opponent)
      .order("wins DESC")
  end
end
