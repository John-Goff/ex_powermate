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

  def event_type(%Event{type: 0}), do: :reset
  def event_type(%Event{type: 1}), do: :press
  def event_type(%Event{type: 2, value: v}) when v <= -1, do: :left_turn
  def event_type(%Event{type: 2, value: v}) when v >= 1, do: :right_turn

  def release?(%Event{type: 1, code: 256, value: 0}), do: true
  def release?(%Event{}), do: false

  def down_press?(%Event{type: 1, code: 256, value: 1}), do: true
  def down_press?(%Event{}), do: false
end

defimpl Inspect, for: ExPowermate.Event do
  def inspect(%ExPowermate.Event{seconds: s, microseconds: m, type: t, code: c, value: v}, _opts) do
    "(#{s}, #{m}, #{t}, #{c}, #{v})"
  end
end
