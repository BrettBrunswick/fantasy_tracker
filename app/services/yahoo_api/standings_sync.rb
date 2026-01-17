module YahooApi
  class StandingsSync
    def initialize(user)
      @user = user
      @client = Client.new(user)
    end

    def sync_season(season, force: false)
      # Skip if standings already exist for all teams (unless forced or current season)
      unless force
        if standings_complete?(season) && season.year < Time.current.year
          Rails.logger.debug("Skipping standings for #{season.league.name} #{season.year} (already synced)")
          return
        end
      end

      response = @client.get_league_standings(season.yahoo_league_key)
      standings_data = extract_standings(response)

      standings_data.each do |standing_data|
        sync_standing(season, standing_data)
      end
    end

    def standings_complete?(season)
      season.standings.count >= season.teams.count && season.teams.any?
    end

    private

    def extract_standings(response)
      standings = response.dig("fantasy_content", "league", 1, "standings", 0, "teams")
      return [] unless standings

      result = []
      standings.each do |key, team_wrapper|
        next unless key.match?(/^\d+$/)
        team_info = team_wrapper["team"]
        next unless team_info

        team_data, team_standings = extract_team_data_and_standings(team_info)
        result << team_data.merge("team_standings" => team_standings) if team_data.is_a?(Hash)
      end

      result
    end

    def extract_team_data_and_standings(team_info)
      if team_info.is_a?(Array)
        team_data = {}
        team_standings = {}
        team_info.each do |item|
          case item
          when Hash
            if item.key?("team_standings")
              team_standings = item["team_standings"]
            else
              team_data.merge!(item)
            end
          when Array
            item.each { |i| team_data.merge!(i) if i.is_a?(Hash) }
          end
        end
        [team_data, team_standings]
      else
        [team_info, {}]
      end
    end

    def sync_standing(season, standing_data)
      team = find_team(season, standing_data)
      return unless team

      standings_info = standing_data["team_standings"]
      return unless standings_info

      outcome_totals = standings_info["outcome_totals"] || {}

      Standing.find_or_initialize_by(
        season: season,
        team: team
      ).update!(
        rank: standings_info["rank"]&.to_i,
        wins: outcome_totals["wins"]&.to_i || 0,
        losses: outcome_totals["losses"]&.to_i || 0,
        ties: outcome_totals["ties"]&.to_i || 0,
        points_for: standings_info["points_for"]&.to_d || 0,
        points_against: standings_info["points_against"]&.to_d || 0
      )
    end

    def find_team(season, standing_data)
      yahoo_team_key = standing_data["team_key"]
      season.teams.find_by(yahoo_team_key: yahoo_team_key)
    end
  end
end
