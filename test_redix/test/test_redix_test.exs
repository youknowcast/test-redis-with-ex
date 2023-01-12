defmodule TestRedixTest do
  use ExUnit.Case
  doctest TestRedix

  setup_all do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 26379)
    Redix.command(conn, ["FLUSHDB"])

    {:ok, conn: conn}
  end

  describe "connect to invalid server" do
    test "returns error" do
      {:ok, conn} = Redix.start_link(host: "invalid", port: 6379)

      assert(
        Redix.command(conn, ["SET", "aaa", "deadbeef"]) ==
          {:error, %Redix.ConnectionError{reason: :closed}}
      )
    end
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

  describe "string:word" do
    test "works", ctx do
      assert(Redix.command(ctx[:conn], ["SET", "myKey", "foo"]) == {:ok, "OK"})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "foo"})

      assert(
        Redix.command(ctx[:conn], ["INCR", "myKey"]) ==
          {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
      )

      assert(
        Redix.command(ctx[:conn], ["DECR", "myKey"]) ==
          {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
      )
    end

    test "command! directly returns value", ctx do
      assert(Redix.command!(ctx[:conn], ["SET", "myKey", "call me stupid."]) == "OK")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey"]) == "call me stupid.")
    end

    test "multibyte code", ctx do
      assert(Redix.command!(ctx[:conn], ["SET", "myKey", "こんにちは，世界"]) == "OK")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey"]) == "こんにちは，世界")

      assert(Redix.command!(ctx[:conn], ["SET", "myKey2", "I♡HIP HOP"]) == "OK")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey2"]) == "I♡HIP HOP")

      assert(Redix.command!(ctx[:conn], ["SET", "I♡HIP HOP", "こんにちは，世界"]) == "OK")
      assert(Redix.command!(ctx[:conn], ["GET", "I♡HIP HOP"]) == "こんにちは，世界")
    end

    test "insert multi k-v once", ctx do
      assert(
        Redix.command!(ctx[:conn], [
          "MSET",
          "myKey",
          "I♡HIP HOP",
          "myKey2",
          "こんにちは，世界",
          "myKey3",
          "call me stupid."
        ]) == "OK"
      )

      assert(Redix.command!(ctx[:conn], ["GET", "myKey"]) == "I♡HIP HOP")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey2"]) == "こんにちは，世界")
      assert(Redix.command!(ctx[:conn], ["GET", "myKey3"]) == "call me stupid.")

      assert(
        Redix.command!(ctx[:conn], ["MGET", "myKey", "myKey2", "myKey3"]) == [
          "I♡HIP HOP",
          "こんにちは，世界",
          "call me stupid."
        ]
      )
    end

    test "with TTL", ctx do
      assert(Redix.command!(ctx[:conn], ["SETEX", "myKey", "300", "call me stupid."]))
      assert(Redix.command!(ctx[:conn], ["GET", "myKey"]) == "call me stupid.")
      assert(Redix.command!(ctx[:conn], ["TTL", "myKey"]) == 300)

      # TTL also integer is allowed
      assert(Redix.command!(ctx[:conn], ["SETEX", "myKey2", 300, "call me stupid."]))
      assert(Redix.command!(ctx[:conn], ["TTL", "myKey2"]) == 300)

      # use MULTI
      assert(
        Redix.transaction_pipeline!(ctx[:conn], [
          ["SET", "myKey3", "foo"],
          ["EXPIRE", "myKey3", 200]
        ]) == ["OK", 1]
      )

      assert(Redix.command!(ctx[:conn], ["TTL", "myKey3"]) == 200)
    end
  end

  describe "string:integer" do
    test "works", ctx do
      assert(Redix.command(ctx[:conn], ["SET", "myKey", 99]) == {:ok, "OK"})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "99"})

      assert(Redix.command(ctx[:conn], ["INCR", "myKey"]) == {:ok, 100})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "100"})

      assert(Redix.command(ctx[:conn], ["DECR", "myKey"]) == {:ok, 99})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "99"})

      assert(Redix.command(ctx[:conn], ["INCRBY", "myKey", 10]) == {:ok, 109})
      assert(Redix.command(ctx[:conn], ["DECRBY", "myKey", 10]) == {:ok, 99})
    end
  end
end
