defmodule ExUnitFileFormatterTest do
  use ExUnit.Case
  doctest ExUnitFileFormatter

  @failed_test %{
    state: {:failed, nil},
    tags: %{file: "a_file"}
  }

  test "smoke test" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      {:ok, pid} = GenServer.start_link(ExUnitFileFormatter, [])
      GenServer.cast(pid, {:suite_started, nil})
      GenServer.cast(pid, {:test_finished, @failed_test})
      GenServer.cast(pid, {:suite_finished, nil, nil})
      # Wait for the GenServer to process it's messages
      _state = :sys.get_state(pid)
    end)
    IO.inspect(output, label: "output")
    assert output == "\nFailed Files:\n1: a_file\n"
  end
end
