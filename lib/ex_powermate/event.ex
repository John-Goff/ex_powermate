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
end

defimpl Inspect, for: ExPowermate.Event do
  def inspect(%ExPowermate.Event{seconds: s, microseconds: m, type: t, code: c, value: v}, _opts) do
    "(#{s}, #{m}, #{t}, #{c}, #{v})"
  end
end
