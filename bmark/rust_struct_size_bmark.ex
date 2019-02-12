defmodule RustStructSizeBmark do
  use Bmark

  bmark :runner do
    IO.inspect(CStruct.struct_size())
  end
end
