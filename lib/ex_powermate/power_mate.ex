defmodule ExPowermate.PowerMate do
  use Bitwise
  alias ExPowermate.Event
  alias ExPowermate.PowerMate

  defstruct [:pid, :file, :path]

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
        %PowerMate{pid: pid, file: fd, path: filename}
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
  @spec wait_for_event(pm :: t(), timeout :: integer() | :infinity) :: t()
  def wait_for_event(pm, timeout \\ 10000)

  def wait_for_event(%PowerMate{pid: pid, file: file} = pm, :infinity) do
    IO.puts("infinity")
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], 'NULL')
    pm
  end

  def wait_for_event(%PowerMate{pid: pid, file: file} = pm, timeout) do
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], %{usec: timeout})
    pm
  end

  @doc """
  Reads data from the PowerMate and returns a list of pending events.

  Returns [:timeout] if no event could be read from the device.
  """
  @spec read_event(t()) :: [Event.t(), ...] | [:timeout]
  def read_event(%PowerMate{pid: pid, file: file}) do
    ssz = struct_size()

    case :prx.read(pid, file, ssz * 32) do
      {:ok, binary} ->
        for <<chunk::binary-size(ssz) <- binary>>,
          do: Event.parse_event(<<chunk::binary-size(ssz)>>)

      _ ->
        [:timeout]
    end
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when brightness < 0 do
    set_led(pm, 0, pulse_speed, pulse_table, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when brightness > 256 do
    set_led(pm, 255, pulse_speed, pulse_table, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when pulse_speed < 0 do
    set_led(pm, brightness, 0, pulse_table, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when pulse_speed > 510 do
    set_led(pm, brightness, 510, pulse_table, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when pulse_table < 0 do
    set_led(pm, brightness, pulse_speed, 0, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{} = pm,
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      )
      when pulse_table > 2 do
    set_led(pm, brightness, pulse_speed, 2, pulse_on_sleep, pulse_on_wake)
  end

  def set_led(
        %PowerMate{pid: parent, file: file},
        brightness,
        pulse_speed,
        pulse_table,
        pulse_on_sleep,
        pulse_on_wake
      ) do
    magic_num =
      brightness ||| pulse_speed <<< 8 ||| pulse_table <<< 17 ||| pulse_on_sleep <<< 19 |||
        pulse_on_wake <<< 20

    data = pack(0, 0, 4, 1, magic_num)

    {:ok, pid} = :prx.fork(parent)
    :prx.write(pid, file, data)
  end

  def pack(sec, mic, typ, cod, val) do
    <<
      sec::native-integer-size(64),
      mic::native-integer-size(64),
      typ::native-integer-size(16),
      cod::native-integer-size(16),
      val::native-integer-size(32)
    >>
  end

  # Checks the size of a C struct using python. Struct refers to the device mapping for
  # the Griffin PowerMate.
  defp struct_size do
    {res, _rem} =
      ~s|python -c "import struct; print struct.calcsize('@llHHi')"|
      |> to_charlist()
      |> :os.cmd()
      |> to_string()
      |> Integer.parse()

    res
  end
end
