defmodule ExPowermate do
  @moduledoc """
  Documentation for ExPowermate.
  """
  alias ExPowermate.Event

  defstruct [:pid, :file]

  def open_device(filename \\ nil) do
    with {:fork, {:ok, pid}} <- {:fork, :prx.fork()},
         {:open, {:ok, fd}} <- {:open, :prx.open(pid, filename, [:o_rdwr])},
         {:ioctl, {:ok, %{arg: arg}}} <- {:ioctl, :prx.ioctl(pid, fd, 0x80ff4506, String.duplicate(<<0>>, 256))} do
      name = String.trim_trailing(arg, <<0>>)
      if name == "Griffin PowerMate" or name == "Griffin SoundKnob" do
        :prx.fcntl(pid, fd, :f_setfl, 2048) # 2048 == O_NDELAY
        %ExPowermate{pid: pid, file: fd}
      else
        :prx.close(pid, fd)
        {:err, "Wrong device"}
      end
    else
      {:fork, _} -> {:err, "Could not fork"}
      {:open, _} -> {:err, "Could not open! path: #{filename}"}
      {:ioctl, _} -> {:err, "Improper ioctl call"}
    end
  end

  @spec wait_for_event(timeout :: integer()) :: Event.t()
  def wait_for_event(%ExPowermate{pid: pid, file: file}, timeout \\ 10) do
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], %{sec: timeout})
    :prx.read(pid, file, 24 * 32)
  end

  def struct_size do
    command = ~s|python -c "import struct; print struct.calcsize('@llHHi')"|
    pid = Port.open({:spawn, command}, [:binary])
    receive do
      {_, {:data, size}} ->
        {int_size, _rem} = Integer.parse(size)
        int_size
      other -> other
    end
  end
end
