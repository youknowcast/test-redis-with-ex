defmodule TestRedix.RedixAgent do
  use Agent

  def start_link do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 26379)

    Agent.start_link(fn -> [conn: conn] end, name: __MODULE__)
  end

  def ping do
    Redix.command!(conn, ["PING"])
  end

  def set(key, value, opts \\ %{}) do
    base = ["SET", key, value]

    ttl =
      if opts[:ttl] do
        ["EX", opts[:ttl]]
      else
        []
      end

    mode =
      case opts[:mode] do
        :create_only -> ["NX"]
        :update_only -> ["XX"]
        nil -> []
      end

    Redix.command!(conn, base ++ mode ++ ttl)
  end

  def mset(list) do
    args =
      list
      |> Enum.map(&Tuple.to_list(&1))
      |> List.flatten()

    Redix.command!(conn(), ["MSET" | args])
  end

  def get(key) do
    Redix.command!(conn(), ["GET", key])
  end

  def ttl(key) do
    Redix.command!(conn(), ["TTL", key])
  end

  def mget(list) when is_list(list) do
    Redix.command!(conn(), ["MGET" | list])
  end

  def mget(_), do: :invalid

  def increment(key, val \\ 1) when is_integer(val) do
    cond do
      val != 1 -> Redix.command!(conn(), ["INCRBY", key, val])
      true -> Redix.command!(conn(), ["INCR", key])
    end
  end

  def increment(_, _), do: :invalid

  def decrement(key, val \\ 1) when is_integer(val) do
    cond do
      val != 1 -> Redix.command!(conn(), ["DECRBY", key, val])
      true -> Redix.command!(conn(), ["DECR", key])
    end
  end

  def decrement(_, _), do: :invalid

  def flushdb do
    Redix.command!(conn(), ["FLUSHDB"])
  end

  def conn do
    Agent.get(__MODULE__, fn config -> config[:conn] end)
  end
end
