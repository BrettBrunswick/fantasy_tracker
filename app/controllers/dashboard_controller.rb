class DashboardController < ApplicationController
  def index
    @leagues = League.includes(:seasons).all
    @recent_matchups = Matchup.includes(:team_1, :team_2, :season)
                              .order(created_at: :desc)
                              .limit(10)
  end
end
