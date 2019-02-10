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
      seconds::size(64),
      microseconds::size(64),
      type::size(16),
      code::size(16),
      value::size(32),
    >> = binary
    %Event{seconds: seconds, microseconds: microseconds, type: type, code: code, value: value}
  end
end
