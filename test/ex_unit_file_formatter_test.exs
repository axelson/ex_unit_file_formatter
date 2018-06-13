defmodule ExUnitFileFormatterTest do
  use ExUnit.Case
  doctest ExUnitFileFormatter

  test "greets the world" do
    assert ExUnitFileFormatter.hello() == :world
  end
end
