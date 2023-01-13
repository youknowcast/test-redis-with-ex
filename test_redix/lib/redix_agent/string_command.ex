defmodule TestRedix.RedixAgent.StringCommand do
  @moduledoc false

  def set(conn, key, value, opts \\ %{}) do
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

    "OK" = Redix.command!(conn, base ++ mode ++ ttl)
    get(conn, key)
  end

  def get(conn, key) do
    Redix.command!(conn, ["GET", key])
  end

  def mset(conn, args) do
    commands =
      args[:list]
      |> Enum.map(&Tuple.to_list(&1))
      |> List.flatten()

    Redix.command!(conn, ["MSET" | commands])
  end

  def mget(conn, args) do
    list = args[:list]

    cond do
      is_list(list) -> Redix.command!(conn, ["MGET" | list])
      true -> :invalid
    end
  end

  def increment(conn, key, val) do
    cond do
      is_integer(val) && val != 1 -> Redix.command!(conn, ["INCRBY", key, val])
      is_integer(val) -> Redix.command!(conn, ["INCR", key])
      true -> :invalid
    end
  end

  def decrement(conn, key, val) do
    cond do
      is_integer(val) && val != 1 -> Redix.command!(conn, ["DECRBY", key, val])
      is_integer(val) -> Redix.command!(conn, ["DECR", key])
      true -> :invalid
    end
  end
end
