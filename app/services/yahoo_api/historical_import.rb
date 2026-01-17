module YahooApi
  class HistoricalImport
    # Yahoo NFL Fantasy Game IDs by year
    GAME_IDS = {
      2024 => 449,
      2023 => 423,
      2022 => 414,
      2021 => 406,
      2020 => 399,
      2019 => 390,
      2018 => 380,
      2017 => 371,
      2016 => 359,
      2015 => 348,
      2014 => 331,
      2013 => 314,
      2012 => 273,
      2011 => 257,
      2010 => 242
    }.freeze

    def initialize(user)
      @user = user
      @league_sync = LeagueSync.new(user)
      @matchup_sync = MatchupSync.new(user)
      @standings_sync = StandingsSync.new(user)
    end

    def import_all_years
      GAME_IDS.keys.sort.reverse.each do |year|
        import_year(year)
      end
    end

    def import_year(year)
      game_id = GAME_IDS[year]
      return unless game_id

      Rails.logger.info("Importing #{year} season (game_id: #{game_id})...")

      client = Client.new(@user)
      response = client.get("/users;use_login=1/games;game_keys=#{game_id}/leagues")

      leagues_data = extract_leagues(response)
      leagues_data.each do |league_data|
        import_league_season(league_data)
      end
    rescue Client::ApiError => e
      if e.message.include?("999")
        Rails.logger.warn("Rate limited fetching #{year}. Waiting 60s before continuing...")
        sleep(60)
        retry
      else
        Rails.logger.error("API error importing year #{year}: #{e.message}")
        raise
      end
    end

    def import_league_season(league_data)
      season = @league_sync.sync_league(league_data)

      if season_needs_sync?(season)
        Rails.logger.info("Syncing season #{season.year} for #{season.league.name}...")
        @standings_sync.sync_season(season)
        @matchup_sync.sync_season(season)
      else
        Rails.logger.info("Skipping season #{season.year} for #{season.league.name} (already synced)")
      end

      season
    rescue Client::ApiError => e
      if e.message.include?("999")
        Rails.logger.warn("Rate limited while syncing #{season&.year} for #{season&.league&.name}. Waiting 60s...")
        sleep(60)
        retry
      else
        Rails.logger.error("API error syncing season: #{e.message}")
        raise
      end
    end

    def season_needs_sync?(season)
      return true if season.teams.empty?
      return true if season.standings.empty?
      return true if season.matchups.empty?

      # For completed seasons (before current year), check if we have enough data
      current_year = Time.current.year
      if season.year < current_year
        team_count = season.teams.count
        # Expect at least 13 weeks of matchups (some leagues have shorter seasons)
        # Each week has team_count/2 matchups
        expected_min_matchups = (team_count / 2) * 13
        return season.matchups.count < expected_min_matchups
      end

      # Current year seasons should always sync to get latest data
      true
    end

    private

    def extract_leagues(response)
      games = response.dig("fantasy_content", "users", "0", "user", 1, "games")
      return [] unless games

      leagues = []
      games.each do |key, game|
        next unless key.match?(/^\d+$/)
        game_leagues = game.dig("game", 1, "leagues")
        next unless game_leagues

        game_leagues.each do |league_key, league_wrapper|
          next unless league_key.match?(/^\d+$/)
          league_info = league_wrapper["league"]
          next unless league_info

          league_data = league_info.is_a?(Array) ? league_info[0] : league_info
          leagues << league_data if league_data
        end
      end

      leagues
    end
  end
end
