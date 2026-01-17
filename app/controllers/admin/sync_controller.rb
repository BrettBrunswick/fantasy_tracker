module Admin
  class SyncController < ApplicationController
    before_action :require_login

    def leagues
      Rails.logger.info "Starting league sync for user #{current_user.id}"
      league_sync = YahooApi::LeagueSync.new(current_user)
      seasons = league_sync.sync_all_leagues
      Rails.logger.info "Synced #{seasons.count} seasons"

      redirect_to root_path, notice: "Synced #{seasons.count} league seasons from Yahoo!"
    rescue YahooApi::Client::AuthenticationError => e
      Rails.logger.error "Auth error: #{e.message}"
      redirect_to root_path, alert: "Authentication failed. Please re-login with Yahoo."
    rescue YahooApi::Client::ApiError => e
      Rails.logger.error "API error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      redirect_to root_path, alert: "Error syncing leagues: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
      redirect_to root_path, alert: "Unexpected error: #{e.message}"
    end

    def season
      season = Season.find(params[:season_id])

      job = SyncSeasonJob.perform_later(current_user.id, season.id)

      current_user.user_jobs.create!(
        job_id: job.job_id,
        job_type: "Sync #{season.league.name} #{season.year}",
        status: "pending",
        started_at: Time.current
      )

      redirect_to league_season_path(season.league, season), notice: "Sync started for #{season.year}. You'll be notified when complete."
    end
  end
end
