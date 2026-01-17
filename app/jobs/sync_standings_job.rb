class SyncStandingsJob < ApplicationJob
  queue_as :sync

  def perform
    User.find_each do |user|
      next unless user.access_token.present?

      begin
        standings_sync = YahooApi::StandingsSync.new(user)

        Season.where(year: Time.current.year).find_each do |season|
          standings_sync.sync_season(season)
        end
      rescue YahooApi::Client::AuthenticationError => e
        Rails.logger.error("Auth error syncing standings for user #{user.id}: #{e.message}")
      rescue YahooApi::Client::ApiError => e
        Rails.logger.error("API error syncing standings for user #{user.id}: #{e.message}")
      end
    end
  end
end
