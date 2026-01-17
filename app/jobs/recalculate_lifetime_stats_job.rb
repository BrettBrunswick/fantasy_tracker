class RecalculateLifetimeStatsJob < ApplicationJob
  queue_as :stats

  def perform(league_id = nil)
    leagues = league_id ? League.where(id: league_id) : League.all

    leagues.find_each do |league|
      Rails.logger.info("Recalculating stats for league: #{league.name}")

      lifetime_calc = Stats::LifetimeCalculator.new(league)
      lifetime_calc.calculate_all

      h2h_calc = Stats::HeadToHeadCalculator.new(league)
      h2h_calc.calculate_all
    end
  end
end
