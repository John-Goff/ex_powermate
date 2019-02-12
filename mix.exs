defmodule ExPowermate.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_powermate,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: "Tools for working with the Griffin PowerMate in Linux with Elixir",
      package: [
        name: "ex_powermate",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/John-Goff/ex_powermate"}
      ],
      source_url: "https://github.com/John-Goff/ex_powermate",
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: rustler_crates(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.19"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bmark, "~> 1.0.0", only: :dev},
      {:prx, git: "https://github.com/msantos/prx.git", branch: "master"}
    ]
  end

  defp rustler_crates do
    [
      c_struct_size: [
        path: "native/c_struct_size",
        mode: rustc_mode(Mix.env())
      ]
    ]
  end

  defp rustc_mode(:prod), do: :release
  defp rustc_mode(_), do: :debug
end
