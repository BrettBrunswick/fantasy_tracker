require_relative "../../lib/omniauth/strategies/yahoo"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :yahoo,
    ENV.fetch("YAHOO_CLIENT_ID", nil),
    ENV.fetch("YAHOO_CLIENT_SECRET", nil),
    scope: "openid",
    callback_url: ENV.fetch("OAUTH_CALLBACK_URL", nil)
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true

# Trust X-Forwarded headers from ngrok
OmniAuth.config.full_host = lambda do |env|
  scheme = env["HTTP_X_FORWARDED_PROTO"] || env["rack.url_scheme"]
  host = env["HTTP_X_FORWARDED_HOST"] || env["HTTP_HOST"]
  "#{scheme}://#{host}"
end
