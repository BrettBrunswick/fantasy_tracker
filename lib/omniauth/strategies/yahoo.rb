require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Yahoo < OmniAuth::Strategies::OAuth2
      option :name, "yahoo"

      option :client_options, {
        site: "https://api.login.yahoo.com",
        authorize_url: "https://api.login.yahoo.com/oauth2/request_auth",
        token_url: "https://api.login.yahoo.com/oauth2/get_token"
      }

      uid { raw_info["sub"] }

      info do
        {
          name: raw_info["name"],
          email: raw_info["email"],
          nickname: raw_info["nickname"],
          image: raw_info["picture"]
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= begin
          access_token.get("https://api.login.yahoo.com/openid/v1/userinfo").parsed
        rescue OAuth2::Error => e
          Rails.logger.warn("Failed to fetch Yahoo user info: #{e.message}")
          {}
        end
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end
