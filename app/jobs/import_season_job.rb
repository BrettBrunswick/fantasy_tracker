class ImportSeasonJob < ApplicationJob
  queue_as :sync

  def perform(user_id, year = nil)
    user = User.find(user_id)
    return unless user.access_token.present?

    historical_import = YahooApi::HistoricalImport.new(user)

    if year
      historical_import.import_year(year)
    else
      historical_import.import_all_years
    end

    RecalculateLifetimeStatsJob.perform_later
  rescue YahooApi::Client::AuthenticationError => e
    Rails.logger.error("Auth error importing for user #{user_id}: #{e.message}")
  rescue YahooApi::Client::ApiError => e
    Rails.logger.error("API error importing for user #{user_id}: #{e.message}")
  end
end
