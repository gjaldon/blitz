defmodule Blitz do
  import Blitz.RiotApiClient
  alias Blitz.DynamicSupervisor

  def find_recently_played_with_matches(summoner_name) do
    with %{"accountId" => account_id} <- get_summoner_by_summoner_name(summoner_name),
         %{"matches" => matches} <- get_recent_matches(account_id, 5) do
      matches
      |> get_all_summoners_in_matches()
      |> watch_summoners()
    end
  end

  defp get_all_summoners_in_matches(matches) do
    matches
    |> Enum.flat_map(fn %{"gameId" => match_id} ->
      result = get_match_by_match_id(match_id)
      result["participantIdentities"]
    end)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {%{"player" => %{"accountId" => account_id}}, index}, acc ->
      summoner_index = index + 1
      summoner_info = get_summoner_by_account_id(account_id)
      matches = get_recent_matches(account_id)["matches"]
      Map.put(acc, :"summoner_#{summoner_index}", %{info: summoner_info, matches: matches})
    end)
  end

  defp watch_summoners(summoners) do
    last_matches_by_summoner =
      for {_key, value} <- summoners, into: %{} do
        account_id = value.info["accountId"]
        [last_match | _] = value.matches
        {account_id, last_match}
      end

    DynamicSupervisor.start_watching(last_matches_by_summoner)

    summoners
  end
end
