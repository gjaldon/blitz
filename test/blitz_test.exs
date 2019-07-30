defmodule BlitzTest do
  use ExUnit.Case
  doctest Blitz

  test "greets the world" do
    assert Blitz.hello() == :world
  end
end
