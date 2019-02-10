defmodule ExPowermate do
  @moduledoc """
  Documentation for ExPowermate.
  """
  use GenServer
  alias ExPowermate.PowerMate

  @impl true
  def init(state) do
    pm = File.ls!("/dev/input")
    |> Enum.filter(&String.starts_with?(&1, "event"))
    |> Enum.map(&PowerMate.open_device/1)
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
    [next | events] = PowerMate.read_event(pm)
    {:reply, next, {pm, events}}
  end
end
