import Config

config :blitz,
  riot_api_base_url: "https://test.com",
  poll_summoner_interval: 50,
  # We stop polling summoner after 5 poll_summoner_intervals
  watcher_lifetime: 3

config :tesla, adapter: Tesla.Mock
