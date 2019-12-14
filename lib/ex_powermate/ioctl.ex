defmodule ExPowermate.IOCTL do
  @moduledoc """
  Performs ioctl operations on the PowerMate
  """

  use Bitwise

  # Shift values
  @ioc_nrshift 0
  @ioc_typeshift 8
  @ioc_sizeshift 16
  @ioc_dirshift 30

  ## Direction bits.
  @ioc_none 0
  @ioc_write 1
  @idc_read 2

  def encode(dir, type, nr, size) do
    dir <<< @ioc_dirshift ||| :binary.first(type) <<< @ioc_typeshift ||| nr <<< @ioc_nrshift |||
      size <<< @ioc_sizeshift
  end

  @doc """
  Gets the ioctl number for the EVIOCGNAME command

  takes the size in bytes that the command should return. Defaults to 255.
  """
  def name(size \\ 255) do
    encode(@idc_read, "E", 0x06, size)
  end
end
