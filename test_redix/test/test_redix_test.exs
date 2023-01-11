defmodule TestRedixTest do
  use ExUnit.Case
  doctest TestRedix

  setup_all do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 26379)
    Redix.command(conn, ["FLUSHDB"])

    {:ok, conn: conn}
  end

  describe "flushdb" do
    test "works", ctx do
      Redix.command(ctx[:conn], ["SET", "flushdb:test", "deadbeef"])
      Redix.command(ctx[:conn], ["FLUSHDB"])

      assert(Redix.command(ctx[:conn], ["GET", "flushdb:test"]) == {:ok, nil})
    end
  end

  describe "ping" do
    test "returns pong", ctx do
      assert(Redix.command(ctx[:conn], ["PING"]) == {:ok, "PONG"})
    end

    test "and ping! directly returns pong", ctx do
      assert(Redix.command!(ctx[:conn], ["PING"]) == "PONG")
    end
  end

  describe "string" do
    test "works", ctx do
      assert(Redix.command(ctx[:conn], ["SET", "myKey", "foo"]) == {:ok, "OK"})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "foo"})

      assert(Redix.command(ctx[:conn], ["INCR", "myKey"]) == {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}})
      assert(Redix.command(ctx[:conn], ["DECR", "myKey"]) == {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}})
    end

    test "command! directly returns value", ctx do
      assert(Redix.command!(ctx[:conn], ["SET", "myKey", "call me stupid."]) == "OK")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey"]) == "call me stupid.")
    end
  end
end
