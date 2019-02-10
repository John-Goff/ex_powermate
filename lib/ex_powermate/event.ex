defmodule ExPowermate.Event do
  defstruct [:seconds, :microseconds, :type, :code, :value]

  @type t() :: %__MODULE__{
    seconds: any(),
    microseconds: any(),
    type: any(),
    code: any(),
    value: any()
  }
end
