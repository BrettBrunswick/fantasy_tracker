class SyncSeasonJob < ApplicationJob
  queue_as :sync

  def perform(user_id, season_id)
    user = User.find(user_id)
    season = Season.find(season_id)

    user_job = UserJob.find_by(job_id: job_id)
    user_job&.update!(status: "running")

    YahooApi::StandingsSync.new(user).sync_season(season)
    YahooApi::MatchupSync.new(user).sync_season(season, force: true)

    Stats::LifetimeCalculator.new(season.league).calculate_all
    Stats::HeadToHeadCalculator.new(season.league).calculate_all

    user_job&.finish!(message: "Synced #{season.league.name} #{season.year}")
  rescue YahooApi::Client::AuthenticationError => e
    user_job&.fail!(message: "Authentication failed. Please re-login.")
    raise
  rescue YahooApi::Client::ApiError => e
    user_job&.fail!(message: e.message)
    raise
  rescue StandardError => e
    user_job&.fail!(message: e.message)
    raise
  end
end
