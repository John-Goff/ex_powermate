# ExPowermate

Tools for working with the Griffin Powermate in Linux with Elixir.

Built on top of [`prx`](https://github.com/msantos/prx), this library allows you to work with
the Griffin PowerMate USB input knob. Unfortunately, this product is discontinued and not
readily available, however, if you have one then they're pretty neat. Usefulness is
limited only by the software available, which is why this library will hopefully expand
the catalogue of software available.

## Installation

Unfortunately, since `prx` is not on hex.pm, this library will need to be installed via git
by adding `ex_powermate` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_powermate, git: "https://github.com/John-Goff/ex_powermate.git", tag: "v0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):
```bash
git clone https://github.com/John-Goff/ex_powermate.git
cd ex_powermate
mix deps.get && mix deps.compile
mix docs
```
