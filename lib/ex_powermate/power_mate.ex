defmodule ExPowermate.Device do
  use Bitwise
  require Logger
  alias ExPowermate.Event
  alias ExPowermate.Device

  defstruct [:pid, :file, :path]

  @type t() :: %__MODULE__{
          pid: pid(),
          file: integer()
        }

  def is_valid?(%Device{pid: pid, file: file}) when is_pid(pid) and is_integer(file), do: true
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
        %Device{pid: pid, file: fd, path: filename}
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
  def wait_for_event(pm, timeout \\ 10_000)

  def wait_for_event(%Device{pid: pid, file: file} = pm, :infinity) do
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], :null)
    pm
  end

  def wait_for_event(%Device{pid: pid, file: file} = pm, timeout) do
    {:ok, _, _, _} = :prx.select(pid, [file], [], [], %{usec: timeout})
    pm
  end

  @doc """
  Reads data from the PowerMate and returns a list of pending events.

  Returns [:timeout] if no event could be read from the device.
  """
  @spec read_event(t()) :: [Event.t(), ...] | [:timeout]
  def read_event(%Device{pid: pid, file: file}) do
    ssz = struct_size()

    case :prx.read(pid, file, ssz * 32) do
      {:ok, binary} ->
        for <<chunk::binary-size(ssz) <- binary>>,
          do: Event.parse_event(<<chunk::binary-size(ssz)>>)

      _ ->
        [:timeout]
    end
  end

  def set_led(%Device{pid: parent, file: file}, b, p, t, s, w) do
    brightness = brightness(b)
    pulse_speed = pulse_speed(p)
    pulse_table = pulse_table(t)
    pulse_on_sleep = pulse_on_sleep(s)
    pulse_on_wake = pulse_on_wake(w)

    magic_num =
      brightness ||| pulse_speed <<< 8 ||| pulse_table <<< 17 ||| pulse_on_sleep <<< 19 |||
        pulse_on_wake <<< 20

    data = pack(0, 0, 4, 1, magic_num)

    {:ok, pid} = :prx.fork(parent)
    :prx.write(pid, file, data)
  end

  defp brightness(b) when b < 0, do: 0
  defp brightness(b) when b > 255, do: 255
  defp brightness(b), do: b
  defp pulse_speed(p) when p < 0, do: 0
  defp pulse_speed(p) when p > 510, do: 510
  defp pulse_speed(p), do: p
  defp pulse_table(p) when p < 0, do: 0
  defp pulse_table(p) when p > 510, do: 510
  defp pulse_table(p), do: p
  defp pulse_on_sleep(true), do: 1
  defp pulse_on_sleep(false), do: 0
  defp pulse_on_sleep(p) when p < 0, do: 0
  defp pulse_on_sleep(p) when p > 1, do: 1
  defp pulse_on_sleep(p), do: p
  defp pulse_on_wake(true), do: 1
  defp pulse_on_wake(false), do: 0
  defp pulse_on_wake(p) when p < 0, do: 0
  defp pulse_on_wake(p) when p > 1, do: 1
  defp pulse_on_wake(p), do: p

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
