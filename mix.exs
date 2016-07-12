defmodule Ev3.Mixfile do
	use Mix.Project

  def project do
    [app: :ev3,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Ev3, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger],
		 env: [{:mock, true},
					 {:platform, :dev}, # platform in [:brickpi, :ev3, :dev]
					 {:nodes, [:"marvin@ukemi", :"rodney@ukemi"]}, # iex --sname marvin etc. for testing. Use --name for actual
					 {:group, :lego},
					 {:robot, [beacon_channel: 2, voice: "en-sc"]}
					] 
		 #		 env: [{:mock, false}, {:platform, :ev3}] # platform in [:brickpi, :ev3, :dev]
		 #		 env: [{:mock, false}, {:platform, :brickpi}] # platform in [:brickpi, :ev3, :dev]
		]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.1.4"},
     {:phoenix_html, "~> 2.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"}]
  end
end
