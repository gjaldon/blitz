import Config

config :blitz,
  riot_api_base_url: "https://na1.api.riotgames.com",
  api_key: System.get_env("API_KEY") || "RGAPI-d4868ec3-d435-4abe-83c7-6cdf0c130e30",
  max_retries: 10,
  # We check summoners' games every 1 minute
  poll_summoner_interval: :timer.minutes(1),
  # This value is 300 because there are 300 minutes in 5 hours
  watcher_lifetime: 300

import_config "#{Mix.env()}.exs"
