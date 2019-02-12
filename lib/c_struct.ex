defmodule CStruct do
  use Rustler, otp_app: :ex_powermate, crate: "c_struct_size"

  def struct_size(), do: :erlang.nif_error(:nif_not_loaded)
end
