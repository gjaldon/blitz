## Usage

Given a valid `summoner_name`, this function will fetch all summoners this
summoner has played with in the last 5 matches. Once fetched, these summoners
will be monitored for new matches every minute in the next 5 hours.

When a summoner plays a new match, the match id is logged to the console.
This functions returns a map of format `%{summoner_1: %{info: info, matches: matches}, ...}`.

```elixir
iex> Blitz.find_recently_played_with_matches("RiotSchmick")
```
