defmodule ExPowermate.Event do
  alias ExPowermate.Event

  defstruct [:seconds, :microseconds, :type, :code, :value]

  @type t() :: %__MODULE__{
          seconds: any(),
          microseconds: any(),
          type: any(),
          code: any(),
          value: any()
        }

  @type history() :: [t()]

  @type event_t() :: :reset | :press | :left_turn | :right_turn

  @doc """
  Turns a binary into a proper event

  Takes a binary returned from reading from the device, and parses it into an event
  struct for further processing.
  """
  @spec parse_event(binary()) :: t()
  def parse_event(binary) do
    <<
      seconds::native-integer-size(64),
      microseconds::native-integer-size(64),
      type::native-integer-size(16),
      code::native-integer-size(16),
      value::signed-native-integer-size(32)
    >> = binary

    %Event{seconds: seconds, microseconds: microseconds, type: type, code: code, value: value}
  end

  @doc """
  Checks the type of an event.
  """
  @spec event_type(t()) :: event_t()
  def event_type(%Event{type: 0}), do: :reset
  def event_type(%Event{type: 1}), do: :press
  def event_type(%Event{type: 2, value: v}) when v <= -1, do: :left_turn
  def event_type(%Event{type: 2, value: v}) when v >= 1, do: :right_turn

  @doc """
  Checks if the powermate is currently pressed down.

  Takes a list of `%Event{}` structs and returns a boolean.
  """
  @spec is_pressed?(history()) :: boolean()
  def is_pressed?(events) do
    press_events = Enum.filter(events, fn e -> event_type(e) == :press end)

    if length(press_events) > 0 do
      down_press?(hd(press_events))
    else
      false
    end
  end

  @doc """
  Checks if a given event is a right turn
  """
  @spec right_turn?(t()) :: boolean()
  def right_turn?(event), do: event_type(event) == :right_turn

  @doc """
  Checks if a given event is a left turn
  """
  @spec left_turn?(t()) :: boolean()
  def left_turn?(event), do: event_type(event) == :left_turn

  @doc """
  Checks if PowerMate is both pressed and turning to the right.
  """
  @spec pressed_turn_right?(t(), history(), integer()) :: boolean()
  def pressed_turn_right?(action, events, speed \\ 5) do
    is_pressed?(events) and right_turn?(action) and debounce(events, :right_turn, speed)
  end

  @doc """
  Checks if PowerMate is both pressed and turning to the left.
  """
  @spec pressed_turn_left?(t(), history(), integer()) :: boolean()
  def pressed_turn_left?(action, events, speed \\ 5) do
    is_pressed?(events) and left_turn?(action) and debounce(events, :left_turn, speed)
  end

  def release?(%Event{type: 1, code: 256, value: 0}), do: true
  def release?(%Event{}), do: false

  def down_press?(%Event{type: 1, code: 256, value: 1}), do: true
  def down_press?(%Event{}), do: false

  @doc """
  Debounces an event to ensure it doesn't fire too rapidly when repeating.
  """
  @spec debounce(history(), event_t(), integer()) :: boolean()
  def debounce([event | events], event_type, mod),
    do: debounce_impl(event, events, event_type, mod, 0)

  defp debounce_impl(event, [], ev_type, mod, acc),
    do:
      if(event_type(event) == ev_type,
        do: rem(acc + 1, mod) == 0,
        else: rem(acc, mod) == 0
      )

  defp debounce_impl(event, [next_event | events], ev_type, mod, acc) do
    if event_type(event) == ev_type do
      debounce_impl(next_event, events, ev_type, mod, acc + 1)
    else
      rem(acc, mod) == 0
    end
  end
end

defimpl Inspect, for: ExPowermate.Event do
  def inspect(%ExPowermate.Event{seconds: s, microseconds: m, type: t, code: c, value: v}, _opts) do
    "(#{s}, #{m}, #{t}, #{c}, #{v})"
  end
end
