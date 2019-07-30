defmodule Blitz do
  import Blitz.RiotApiClient

  def find_recently_played_with_matches(summoner_name) do
    with %{"accountId" => account_id} <- get_summoner_by_summoner_name(summoner_name),
         %{"matches" => matches} <- get_recent_matches(account_id, 5),
         do: get_all_summoners_in_matches(matches)
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
      matches = get_recent_matches_without_retries(account_id)
      Map.put(acc, :"summoner_#{summoner_index}", %{info: summoner_info, matches: matches})
    end)
  end
end
