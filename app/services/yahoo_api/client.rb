module YahooApi
  class Client
    BASE_URL = "https://fantasysports.yahooapis.com"

    class AuthenticationError < StandardError; end
    class ApiError < StandardError; end

    def initialize(user)
      @user = user
      refresh_token_if_needed!
    end

    def get(path, params = {})
      full_path = "/fantasy/v2#{path}"
      full_path += path.include?("?") ? "&format=json" : "?format=json"

      response = connection.get(full_path) do |req|
        req.params.merge!(params) if params.any?
      end

      handle_response(response)
    end

    def get_user_leagues
      # Get all NFL fantasy leagues across all seasons
      # game_keys=nfl returns all NFL fantasy football games the user has participated in
      get("/users;use_login=1/games;game_keys=nfl/leagues")
    end

    def get_league(league_key)
      get("/league/#{league_key}")
    end

    def get_league_standings(league_key)
      get("/league/#{league_key}/standings")
    end

    def get_league_scoreboard(league_key, week: nil)
      path = "/league/#{league_key}/scoreboard"
      path += ";week=#{week}" if week
      get(path)
    end

    def get_league_teams(league_key)
      get("/league/#{league_key}/teams")
    end

    def get_team_roster(team_key, week: nil)
      path = "/team/#{team_key}/roster"
      path += ";week=#{week}" if week
      get(path)
    end

    def get_matchups(league_key, week: nil)
      path = "/league/#{league_key}/scoreboard"
      path += ";week=#{week}" if week
      get(path)
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.request :authorization, "Bearer", @user.access_token
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    def refresh_token_if_needed!
      return unless @user.token_expired?

      oauth_client = OAuth2::Client.new(
        Rails.application.credentials.dig(:yahoo, :client_id),
        Rails.application.credentials.dig(:yahoo, :client_secret),
        site: "https://api.login.yahoo.com",
        token_url: "/oauth2/get_token"
      )

      token = OAuth2::AccessToken.new(
        oauth_client,
        @user.access_token,
        refresh_token: @user.refresh_token
      )

      new_token = token.refresh!

      @user.update!(
        access_token: new_token.token,
        refresh_token: new_token.refresh_token,
        token_expires_at: Time.at(new_token.expires_at)
      )

      @connection = nil
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 401
        raise AuthenticationError, "Authentication failed. Please re-authenticate with Yahoo."
      when 400..499
        raise ApiError, "Client error: #{response.status} - #{response.body}"
      when 500..599
        raise ApiError, "Server error: #{response.status} - #{response.body}"
      else
        raise ApiError, "Unexpected response: #{response.status}"
      end
    end
  end
end
