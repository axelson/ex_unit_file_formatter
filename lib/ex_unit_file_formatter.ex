defmodule ExUnitFileFormatter do
  use GenServer

  @impl true
  def init(_) do
    {:ok, %{failed_files: %{}}}
  end

  @impl true
  def handle_cast({:suite_started, _opts}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:suite_finished, _times_us}, state) do
    print_failed_files(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_finished, %{state: nil}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:test_finished, %{state: {:failed, _}} = test}, state) do
    file = test.tags.file

    state = record_file_failed(state, file)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sigquit, modules}, state) do
    IO.puts("SIGQUIT with modules #{inspect(modules)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(_event, state) do
    {:noreply, state}
  end

  defp record_file_failed(%{failed_files: failed_files_map} = state, file) do
    failed_files_map = Map.update(failed_files_map, file, 1, &(&1 + 1))
    Map.put(state, :failed_files, failed_files_map)
  end

  defp print_failed_files(%{failed_files: failed_files_map}) do
    failed_file_list =
      failed_files_map
      |> Map.to_list()
      |> Enum.sort(fn {_, count1}, {_, count2} ->
        count1 >= count2
      end)

    if length(failed_file_list) > 0 do
      IO.puts("\nFailed Files:")

      failed_file_list
      |> Enum.each(fn {file, count} ->
        IO.puts("#{count}: #{file}")
      end)
    else
      IO.puts("\nTests all finished successfully")
    end
  end
end
