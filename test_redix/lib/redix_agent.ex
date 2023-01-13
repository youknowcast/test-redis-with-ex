defmodule TestRedix.RedixAgent do
  @moduledoc false

  use GenServer
  use Agent

  alias TestRedix.RedixAgent.StringCommand

  @agent String.to_atom("#{__MODULE__}:redis_agent")

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def set(key, value, opts \\ %{}) do
    GenServer.call(__MODULE__, {:string, :set, %{key: key, value: value, opts: opts}})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:string, :get, %{key: key}})
  end

  def mset(list) do
    GenServer.call(__MODULE__, {:string, :mset, %{list: list}})
  end

  def mget(list) do
    GenServer.call(__MODULE__, {:string, :mget, %{list: list}})
  end

  def increment(key, val \\ 1) do
    GenServer.call(__MODULE__, {:string, :increment, %{key: key, val: val}})
  end

  def decrement(key, val \\ 1) do
    GenServer.call(__MODULE__, {:string, :decrement, %{key: key, val: val}})
  end

  def ping do
    Redix.command!(conn(), ["PING"])
  end

  def ttl(key) do
    Redix.command!(conn(), ["TTL", key])
  end

  def flushdb do
    Redix.command!(conn(), ["FLUSHDB"])
  end

  def conn do
    Agent.get(@agent, fn config -> config[:conn] end)
  end

  def init(config) do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 26379)

    Agent.start_link(fn -> [conn: conn] end, name: @agent)

    {:ok, config}
  end

  def handle_call({:string, command, args}, _, state) do
    value =
      case command do
        :set -> StringCommand.set(conn(), args[:key], args[:value], args[:opts])
        :get -> StringCommand.get(conn(), args[:key])
        :mset -> StringCommand.mset(conn(), args)
        :mget -> StringCommand.mget(conn(), args)
        :increment -> StringCommand.increment(conn(), args[:key], args[:val])
        :decrement -> StringCommand.decrement(conn(), args[:key], args[:val])
      end

    {:reply, value, state}
  end
end
