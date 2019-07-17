defmodule ExPowermate do
  @moduledoc """
  Tools for working with the Griffin PowerMate in Linux with Elixir.

  ## Usage
  Main intended usage is as a GenServer. `start_link/0` and `start_link/1` provide
  functionality to start the GenServer. Once started, `next_event/1` fetches the next
  event from the device and returns it for further use. `print_incoming_events/1` will
  print all incoming events in a continuous loop, useful for inspecting the events
  being emitted.

  ## Example
  ```
  iex> {:ok, pid} = ExPowermate.start_link()
  iex> ExPowermate.next_event(pid)
  %ExPowermate.Event{}
  ```

  ## The PowerMate
  The Griffin PowerMate is really simple, basically just a USB potentiometer, with a
  "click" when the knob is pressed down. Its practicality is therefore determined by
  the quality of software available. Currently (2019), the state of PowerMate software
  under Linux is decades old blog posts riddled with broken links, with almost no
  software actually able to use the PowerMate. I predict that this library will be
  seldom used, being the intersection between niche hardware and a niche OS, however
  I hope this inspires someone to write some software for the PowerMate.
  """
  use GenServer
  alias ExPowermate.PowerMate

  @doc """
  Starts GenServer and opens PowerMate.
  """
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, [], opts)

  @doc """
  Gets the next Event emitted by the PowerMate.

  Returns an `ExPowermate.Event` struct representing the fired event. See
  `ExPowermate.Event` for more.
  """
  def next_event(pid), do: GenServer.call(pid, :next_event, :infinity)

  @doc """
  Starts an endless loop, printing all events that come in.

  Useful mainly for debugging and developing new applications.
  """
  def print_incoming_events(pid) do
    IO.inspect(next_event(pid))
    print_incoming_events(pid)
  end

  @doc false
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

  @doc false
  @impl true
  def handle_call(:next_event, _from, {pm, [next | events]}) do
    {:reply, next, {pm, events}}
  end

  @doc false
  @impl true
  def handle_call(:next_event, _from, {pm, []}) do
    [next | events] =
      pm
      |> PowerMate.wait_for_event()
      |> PowerMate.read_event()

    {:reply, next, {pm, events}}
  end
end
