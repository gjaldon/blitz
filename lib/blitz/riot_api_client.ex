defmodule Blitz.RiotApiClient do
  use Tesla
  require Logger

  @moduledoc """
  This api client respects the Riot API's rate limits. Once the rate limit has
  been reached, the request will be retried after the specified number of
  seconds in Riot's "retry-after" header that it sends in its 429 response.

  All requests sent to the Riot API will have this retry functionality.
  """

  @max_retries Application.get_env(:blitz, :max_retries)

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:blitz, :riot_api_base_url))
  plug(Tesla.Middleware.Query, api_key: Application.get_env(:blitz, :api_key))
  plug(Tesla.Middleware.JSON)

  def get_summoner_by_summoner_name(summoner_name) do
    path = Path.join("lol/summoner/v4/summoners/by-name", summoner_name)
    get_with_retries(path)
  end

  def get_recent_matches(account_id, end_index \\ 5) do
    path = Path.join("lol/match/v4/matchlists/by-account", "#{account_id}")
    get_with_retries(path, query: [endIndex: end_index])
  end

  def get_summoner_by_account_id(account_id) do
    path = Path.join("lol/summoner/v4/summoners/by-account", "#{account_id}")
    get_with_retries(path)
  end

  def get_match_by_match_id(match_id) do
    path = Path.join("lol/match/v4/matches", "#{match_id}")
    get_with_retries(path)
  end

  defp get_with_retries(path, opts \\ [], retries \\ 0) do
    if retries < @max_retries do
      Logger.debug("Sending request to #{path}")

      case get(path, opts) do
        {:ok, %{status: 200} = response} ->
          response.body

        {:ok, %{status: 429, headers: headers}} ->
          retry_delay = :proplists.get_value("retry-after", headers) |> String.to_integer()
          Logger.debug("Rate limit reached. Will retry after #{retry_delay} second/s.")
          Process.sleep(retry_delay * 1000)
          Logger.debug("Retrying sending request to path")
          get_with_retries(path, opts, retries + 1)

        {:error, error} ->
          raise "Error met: #{inspect(error)}"

        {:ok, %{status: status_code}} ->
          raise "Unhandled status code: #{inspect(status_code)}"

        {:ok, response} ->
          raise "Unhandled case: #{inspect(response)}"
      end
    else
      raise "Max retries of #{@max_retries} reached."
    end
  end
end
