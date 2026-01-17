module YahooApi
  class MatchupSync
    REGULAR_SEASON_WEEKS = 1..14
    PLAYOFF_WEEKS = 15..17

    def initialize(user)
      @user = user
      @client = Client.new(user)
    end

    def sync_season(season, force: false)
      (1..17).each do |week|
        sync_week(season, week, force: force)
      end
    end

    def sync_week(season, week, force: false)
      # Skip if week already has matchups (unless forced or current season)
      unless force
        existing_matchups = season.matchups.where(week: week).count
        expected_matchups = season.teams.count / 2

        if existing_matchups >= expected_matchups && season.year < Time.current.year
          Rails.logger.debug("Skipping week #{week} for #{season.league.name} #{season.year} (already synced)")
          return
        end
      end

      response = @client.get_matchups(season.yahoo_league_key, week: week)
      matchups_data = extract_matchups(response, week)

      matchups_data.each do |matchup_data|
        sync_matchup(season, week, matchup_data)
      end
    end

    def sync_current_week(season)
      response = @client.get_league(season.yahoo_league_key)
      current_week = extract_current_week(response)
      sync_week(season, current_week) if current_week
    end

    private

    def extract_matchups(response, week)
      scoreboard = response.dig("fantasy_content", "league", 1, "scoreboard")
      return [] unless scoreboard

      matchups = scoreboard.dig("0", "matchups") || scoreboard["matchups"]
      return [] unless matchups

      result = []
      matchups.each do |key, matchup_wrapper|
        next unless key.match?(/^\d+$/)
        matchup_info = matchup_wrapper["matchup"]
        next unless matchup_info

        result << matchup_info
      end

      result
    end

    def extract_current_week(response)
      response.dig("fantasy_content", "league", 0, "current_week")&.to_i
    end

    def sync_matchup(season, week, matchup_data)
      teams_data = extract_matchup_teams(matchup_data)
      return if teams_data.length < 2

      team_1_data = teams_data[0]
      team_2_data = teams_data[1]

      team_1 = find_team(season, team_1_data)
      team_2 = find_team(season, team_2_data)

      return unless team_1 && team_2

      team_1_score = extract_score(team_1_data)
      team_2_score = extract_score(team_2_data)

      matchup_type = determine_matchup_type(matchup_data, week)
      winner = determine_winner(team_1, team_2, team_1_score, team_2_score)

      matchup = Matchup.find_or_initialize_by(
        season: season,
        week: week,
        team_1: team_1,
        team_2: team_2
      )

      matchup.update!(
        team_1_score: team_1_score,
        team_2_score: team_2_score,
        winner: winner,
        matchup_type: matchup_type,
        yahoo_matchup_key: matchup_data["matchup_key"]
      )

      sync_matchup_players(matchup, team_1, team_1_data)
      sync_matchup_players(matchup, team_2, team_2_data)

      matchup
    end

    def extract_matchup_teams(matchup_data)
      teams = matchup_data.dig("0", "teams") || matchup_data["teams"]
      return [] unless teams

      result = []
      teams.each do |key, team_wrapper|
        next unless key.match?(/^\d+$/)
        team_info = team_wrapper["team"]
        next unless team_info

        team_data, team_points = extract_team_data_and_points(team_info)
        result << team_data.merge("team_points" => team_points) if team_data.is_a?(Hash)
      end

      result
    end

    def extract_team_data_and_points(team_info)
      if team_info.is_a?(Array)
        team_data = {}
        team_points = {}
        team_info.each do |item|
          case item
          when Hash
            if item.key?("team_points")
              team_points = item["team_points"]
            else
              team_data.merge!(item)
            end
          when Array
            item.each { |i| team_data.merge!(i) if i.is_a?(Hash) }
          end
        end
        [team_data, team_points]
      else
        [team_info, {}]
      end
    end

    def find_team(season, team_data)
      yahoo_team_key = team_data["team_key"]
      season.teams.find_by(yahoo_team_key: yahoo_team_key)
    end

    def extract_score(team_data)
      points = team_data.dig("team_points", "total")
      points&.to_d
    end

    def determine_matchup_type(matchup_data, week)
      is_playoffs = matchup_data["is_playoffs"] == "1"
      is_consolation = matchup_data["is_consolation"] == "1"
      is_championship = matchup_data["is_championship"] == "1"

      if is_championship
        :championship
      elsif is_consolation
        :consolation
      elsif is_playoffs || week > 14
        :playoff
      else
        :regular_season
      end
    end

    def determine_winner(team_1, team_2, score_1, score_2)
      return nil if score_1.nil? || score_2.nil?
      return nil if score_1 == score_2

      score_1 > score_2 ? team_1 : team_2
    end

    def sync_matchup_players(matchup, team, team_data)
      response = @client.get_team_roster(team.yahoo_team_key, week: matchup.week)
      players_data = extract_roster_players(response)

      players_data.each do |player_data|
        sync_player(matchup, team, player_data)
      end
    rescue YahooApi::Client::ApiError => e
      Rails.logger.warn("Failed to sync players for team #{team.id}: #{e.message}")
    end

    def extract_roster_players(response)
      roster = response.dig("fantasy_content", "team", 1, "roster")
      return [] unless roster

      players = roster.dig("0", "players") || roster["players"]
      return [] unless players

      result = []
      players.each do |key, player_wrapper|
        next unless key.match?(/^\d+$/)
        player_info = player_wrapper["player"]
        next unless player_info

        player_data, player_points = extract_player_data_and_points(player_info)
        result << player_data.merge("player_points" => player_points) if player_data.is_a?(Hash)
      end

      result
    end

    def extract_player_data_and_points(player_info)
      if player_info.is_a?(Array)
        player_data = {}
        player_points = {}
        player_info.each do |item|
          case item
          when Hash
            if item.key?("player_points")
              player_points = item["player_points"]
            else
              player_data.merge!(item)
            end
          when Array
            item.each { |i| player_data.merge!(i) if i.is_a?(Hash) }
          end
        end
        [player_data, player_points]
      else
        [player_info, {}]
      end
    end

    def sync_player(matchup, team, player_data)
      yahoo_player_key = player_data["player_key"]
      player_name = extract_player_name(player_data)
      position = extract_position(player_data)
      points = extract_player_points(player_data)

      MatchupPlayer.find_or_initialize_by(
        matchup: matchup,
        team: team,
        yahoo_player_key: yahoo_player_key
      ).update!(
        player_name: player_name,
        position: position,
        points: points
      )
    end

    def extract_player_name(player_data)
      name_data = player_data["name"]
      return "Unknown" unless name_data

      name_data["full"] || "#{name_data['first']} #{name_data['last']}"
    end

    def extract_position(player_data)
      player_data["display_position"] || player_data["primary_position"]
    end

    def extract_player_points(player_data)
      player_data.dig("player_points", "total")&.to_d
    end
  end
end
