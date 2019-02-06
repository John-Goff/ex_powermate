defmodule ExPowermate do
  @moduledoc """
  Documentation for ExPowermate.
  """
  @behaviour :gen_statem

  @server_name :powermate_statem

  ## Module API

  def start, do: :gen_statem.start({:local, @server_name}, __MODULE__, [], [])

  def stop, do: :gen_statem.stop(@server_name)

  def open_device(filename \\ nil) do
    with {:fork, {:ok, pid}} <- {:fork, :prx.fork()},
         {:open, {:ok, fd}} <- {:open, :prx.open(pid, filename, [:o_rdwr])},
         {:ioctl, {:ok, %{arg: arg}}} <- {:ioctl, :prx.ioctl(pid, fd, 0x80ff4506, String.duplicate(<<0>>, 256))} do
      name = String.trim_trailing(arg, <<0>>)
      if name == "Griffin PowerMate" or name == "Griffin SoundKnob" do
        :prx.fcntl(pid, fd, :f_setfl, 2048) # 2048 == O_NDELAY
        {:ok, pid, fd}
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
end
