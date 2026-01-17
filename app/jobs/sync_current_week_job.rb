class SyncCurrentWeekJob < ApplicationJob
  queue_as :sync

  def perform
    User.find_each do |user|
      next unless user.access_token.present?

      begin
        matchup_sync = YahooApi::MatchupSync.new(user)

        Season.where(year: Time.current.year).find_each do |season|
          matchup_sync.sync_current_week(season)
        end
      rescue YahooApi::Client::AuthenticationError => e
        Rails.logger.error("Auth error syncing for user #{user.id}: #{e.message}")
      rescue YahooApi::Client::ApiError => e
        Rails.logger.error("API error syncing for user #{user.id}: #{e.message}")
      end
    end
  end
end
