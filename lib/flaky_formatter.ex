defmodule FlakyFormatter do
  use GenServer

  defmodule State do
    defstruct [:root_dir, :test_failures, :suite_failed?]
  end

  defmodule TestFailure do
    defstruct [:id, :state]

    def to_test_failure(%ExUnit.Test{} = test) do
      %TestFailure{
        id: "#{test.module} - #{test.name}",
        state: test.state
      }
    end
  end

  defmodule TestOutput do
    @derive Jason.Encoder
    defstruct [:num_runs, :successful_runs, :failed_runs, :test_failures]

    def new do
      %__MODULE__{
        num_runs: 0,
        successful_runs: 0,
        failed_runs: 0,
        test_failures: %{}
      }
    end

    def from_json(json) do
      %__MODULE__{
        num_runs: json["num_runs"],
        successful_runs: json["successful_runs"],
        failed_runs: json["failed_runs"],
        test_failures: json["test_failures"]
      }
    end
  end

  @impl GenServer
  def init(_opts) do
    root_dir = File.cwd!()
    state = %State{root_dir: root_dir, test_failures: [], suite_failed?: false}
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:suite_started, _opts}, state) do
    # IO.inspect(opts, label: "opts (flaky_formatter.ex:17)")
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    print_results(state)
    {:noreply, state}
  end

  # TODO: Is this needed?
  def handle_cast(
        {:module_finished, %ExUnit.TestModule{state: {:failed, failures}} = test_module},
        state
      ) do
    IO.puts("FAILURE!!!")
    # iex> failure = {:error, catch_error(raise "oops"), _stacktrace = []}
    # iex> formatter_cb = fn _key, value -> value end
    # iex> test_module = %ExUnit.TestModule{name: Hello}
    # iex> format_test_all_failure(test_module, [failure], 1, 80, formatter_cb)
    ExUnit.Formatter.format_test_all_failure(
      test_module,
      failures,
      99,
      80,
      fn _key, value -> value end
    )
    |> IO.puts()

    {:noreply, state}
  end

  def handle_cast({:test_finished, %{state: nil}}, state) do
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, failures}} = test}, state) do
    formatted =
      ExUnit.Formatter.format_test_failure(
        test,
        failures,
        1,
        100,
        fn _key, value -> value end
      )

    IO.puts(formatted)
    state = track_test_failure(state, test)
    {:noreply, state}
  end

  def handle_cast(_event, state) do
    # IO.inspect(event, label: "event (flaky_formatter.ex:76)")
    {:noreply, state}
  end

  defp track_test_failure(%State{} = state, %ExUnit.Test{} = test) do
    test_failures = [TestFailure.to_test_failure(test) | state.test_failures]
    %State{state | test_failures: test_failures, suite_failed?: true}
  end

  defp print_results(%State{} = state) do
    # In a file I want to store
    # - How many times the test suite has been run
    # - How many times each test has failed
    #   - And with what error
    # Ideally I want this to be thread-safe, but not necesarily
    test_output =
      case File.read("test_output.json") do
        {:error, :enoent} ->
          TestOutput.new()

        {:ok, json_string} ->
          Jason.decode!(json_string)
          |> TestOutput.from_json()

          # TestOutput.new()
      end

    this_run_test_failures =
      state.test_failures
      |> Enum.map(fn test_failure ->
        %{
          id: test_failure.id,
          state: inspect(test_failure.state, pretty: true, limit: :infinity)
        }
      end)
      |> Enum.group_by(& &1.id)

    test_failures =
      Map.merge(
        test_output.test_failures,
        this_run_test_failures,
        fn _key, value1, value2 ->
          value1 ++ value2
        end
      )

    successful? = !state.suite_failed?

    test_output = %TestOutput{
      test_output
      | num_runs: test_output.num_runs + 1,
        successful_runs: increment_if_true(test_output.successful_runs, successful?),
        failed_runs: increment_if_true(test_output.failed_runs, !successful?),
        test_failures: test_failures
    }

    File.write("test_output.json", Jason.encode!(test_output))
  end

  defp increment_if_true(value, true), do: value + 1
  defp increment_if_true(value, false), do: value
end
