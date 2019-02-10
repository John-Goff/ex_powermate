defmodule ExPowermate.PowerMate do
  alias ExPowermate.Event
  alias ExPowermate.PowerMate

  defstruct [:pid, :file]

  @type t() :: %__MODULE__{
          pid: pid(),
          file: integer()
        }

  def is_valid?(%PowerMate{pid: pid, file: file}) when is_pid(pid) and is_integer(file), do: true
  def is_valid?(_), do: false

  @doc """
  Opens device at path and checks if it is a PowerMate.
  """
  @spec open_device(filename :: String.t()) :: t()
  def open_device(filename) do
    with {:fork, {:ok, pid}} <- {:fork, :prx.fork()},
         {:open, {:ok, fd}} <- {:open, :prx.open(pid, filename, [:o_rdwr])},
         {:ioctl, {:ok, %{arg: arg}}} <-
           {:ioctl, :prx.ioctl(pid, fd, 0x80FF4506, String.duplicate(<<0>>, 256))} do
      name = String.trim_trailing(arg, <<0>>)

      if name == "Griffin PowerMate" or name == "Griffin SoundKnob" do
        # 2048 == O_NDELAY
        :prx.fcntl(pid, fd, :f_setfl, 2048)
        %PowerMate{pid: pid, file: fd}
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

  @doc """
  Blocks until event is pending or timeout reached.

  Timeout defaults to ten seconds. Returns :ok when the device can be read from.
  """
  @spec wait_for_event(pm :: t(), timeout :: integer()) :: t()
  def wait_for_event(%PowerMate{pid: pid, file: file} = pm, timeout \\ 10) do
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], %{sec: timeout})
    pm
  end

  @doc """
  Reads data from the PowerMate and returns a list of pending events.

  Returns [:timeout] if no event could be read from the device.
  """
  @spec read_event(t()) :: [Event.t(), ...] | [:timeout]
  def read_event(%PowerMate{pid: pid, file: file}) do
    ssz = struct_size()

    case :prx.read(pid, file, struct_size() * 32) do
      {:ok, binary} ->
        for <<chunk::binary-size(ssz) <- binary>>,
          do: Event.parse_event(<<chunk::binary-size(ssz)>>)

      _ ->
        [:timeout]
    end
  end

  # Checks the size of a C struct using python. Struct refers to the device mapping for
  # the Griffin PowerMate.
  defp struct_size do
    command = ~s|python -c "import struct; print struct.calcsize('@llHHi')"|
    Port.open({:spawn, command}, [:binary])

    receive do
      {_, {:data, size}} ->
        {int_size, _rem} = Integer.parse(size)
        int_size

      other ->
        other
    end
  end
end
