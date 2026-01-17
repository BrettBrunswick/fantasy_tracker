module YahooApi
  class LeagueSync
    def initialize(user)
      @user = user
      @client = Client.new(user)
    end

    def sync_all_leagues
      response = @client.get_user_leagues
      leagues_data = extract_leagues(response)

      leagues_data.map do |league_data|
        sync_league(league_data)
      end
    end

    def sync_league(league_data)
      yahoo_league_key = league_data["league_key"]
      season_year = extract_year(league_data)

      league = find_or_create_league(league_data)
      season = find_or_create_season(league, league_data, season_year)

      sync_teams(season, yahoo_league_key)

      season
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

    def extract_year(league_data)
      league_data["season"].to_i
    end

    def find_or_create_league(league_data)
      name = league_data["name"]

      League.find_or_create_by!(name: name) do |league|
        league.yahoo_league_key = league_data["league_key"]
      end
    end

    def find_or_create_season(league, league_data, year)
      Season.find_or_create_by!(league: league, year: year) do |season|
        season.yahoo_league_key = league_data["league_key"]
        season.yahoo_game_id = league_data["game_code"]
      end
    end

    def sync_teams(season, yahoo_league_key)
      response = @client.get_league_teams(yahoo_league_key)
      teams_data = extract_teams(response)

      teams_data.each do |team_data|
        sync_team(season, team_data)
      end
    end

    def extract_teams(response)
      teams = response.dig("fantasy_content", "league", 1, "teams")
      return [] unless teams

      result = []
      teams.each do |key, team_wrapper|
        next unless key.match?(/^\d+$/)
        team_info = team_wrapper["team"]
        next unless team_info

        # Yahoo returns team data as array of arrays/hashes - flatten and merge
        if team_info.is_a?(Array)
          team_data = {}
          flatten_and_merge(team_info, team_data)
          result << team_data
        else
          result << team_info
        end
      end

      result
    end

    def sync_team(season, team_data)
      yahoo_team_key = team_data["team_key"]
      name = team_data["name"]
      manager_data = extract_manager(team_data)

      manager = find_or_create_manager(manager_data)

      Team.find_or_create_by!(yahoo_team_key: yahoo_team_key) do |team|
        team.season = season
        team.manager = manager
        team.name = name
      end
    end

    def extract_manager(team_data)
      managers = team_data["managers"]
      return {} unless managers

      # Yahoo API returns managers in different formats:
      # - Array: [{"manager" => {...}}]
      # - Hash: {"0" => {"manager" => {...}}}
      if managers.is_a?(Array)
        manager_info = managers.first&.dig("manager")
      else
        manager_info = managers.dig("0", "manager")
      end
      manager_info || {}
    end

    def find_or_create_manager(manager_data)
      return Manager.find_or_create_by!(name: "Unknown") if manager_data.empty?

      yahoo_guid = manager_data["guid"]
      name = manager_data["nickname"] || manager_data["name"] || "Unknown"

      if yahoo_guid
        Manager.find_or_create_by!(yahoo_guid: yahoo_guid) do |m|
          m.name = name
        end
      else
        Manager.find_or_create_by!(name: name)
      end
    end

    def flatten_and_merge(data, result)
      case data
      when Hash
        result.merge!(data)
      when Array
        data.each { |item| flatten_and_merge(item, result) }
      end
    end
  end
end
