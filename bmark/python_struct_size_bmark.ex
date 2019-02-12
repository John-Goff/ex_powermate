defmodule PythonStructSizeBmark do
  use Bmark

  bmark :runner do
    IO.inspect(ExPowermate.PowerMate.struct_size())
  end
end
