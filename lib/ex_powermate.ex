defmodule ExPowermate do
  @moduledoc """
  Documentation for ExPowermate.
  """
  use GenServer
  alias ExPowermate.PowerMate

  def start_link(events) when is_list(events), do: GenServer.start_link(__MODULE__, events)

  def print_incoming_events(pid) do
    IO.inspect(GenServer.call(pid, :next_event, :infinity))
    print_incoming_events(pid)
  end

  @impl true
  def init(state) do
    pm =
      File.ls!("/dev/input")
      |> Enum.filter(&String.starts_with?(&1, "event"))
      |> Enum.map(&PowerMate.open_device("/dev/input/" <> &1))
      |> Enum.find(&PowerMate.is_valid?/1)

    if is_nil(pm) do
      {:stop, "Could not open PowerMate"}
    else
      {:ok, {pm, state}}
    end
  end

  @impl true
  def handle_call(:next_event, _from, {pm, [next | events]}) do
    {:reply, next, {pm, events}}
  end

  @impl true
  def handle_call(:next_event, _from, {pm, []}) do
    [next | events] =
      pm
      |> PowerMate.wait_for_event()
      |> PowerMate.read_event()

    {:reply, next, {pm, events}}
  end
end
