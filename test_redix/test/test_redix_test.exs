defmodule TestRedixTest do
  use ExUnit.Case
  doctest TestRedix

  alias TestRedix.RedixAgent

  setup_all do
    RedixAgent.start_link()

    {:ok, %{}}
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
    test "works" do
      RedixAgent.set("flushdb:test", "deadbeef")
      RedixAgent.flushdb()

      assert(RedixAgent.get("flushdb:test") == nil)
    end
  end

  describe "ping" do
    test "returns pong" do
      assert(RedixAgent.ping() == "PONG")
    end
  end

  describe "string:word" do
    test "works" do
      assert(RedixAgent.set("myKey", "foo") == "OK")
      assert(RedixAgent.get("myKey") == "foo")

      # default Redix behavior when incr command executed with non-integer value
      assert(
        Redix.command(RedixAgent.conn(), ["INCR", "myKey"]) ==
          {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
      )

      assert(
        Redix.command(RedixAgent.conn(), ["DECR", "myKey"]) ==
          {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
      )
    end

    test "command! directly returns value" do
      # default Redix behavior
      assert(Redix.command!(RedixAgent.conn(), ["SET", "myKey", "call me stupid."]) == "OK")
      assert(Redix.command!(RedixAgent.conn(), ["GET", "myKey"]) == "call me stupid.")
    end

    test "multibyte code" do
      assert(RedixAgent.set("myKey", "こんにちは，世界") == "OK")
      assert(RedixAgent.get("myKey") == "こんにちは，世界")

      assert(RedixAgent.set("myKey2", "I♡HIP HOP") == "OK")
      assert(RedixAgent.get("myKey2") == "I♡HIP HOP")

      assert(RedixAgent.set("I♡HIP HOP", "こんにちは，世界") == "OK")
      assert(RedixAgent.get("I♡HIP HOP") == "こんにちは，世界")
    end

    test "insert multi k-v once" do
      assert(
        RedixAgent.mset(
          myKey: "I♡HIP HOP",
          myKey2: "こんにちは，世界",
          myKey3: "call me stupid."
        ) == "OK"
      )

      assert(RedixAgent.get("myKey") == "I♡HIP HOP")
      assert(RedixAgent.get("myKey2") == "こんにちは，世界")
      assert(RedixAgent.get("myKey3") == "call me stupid.")

      assert(
        RedixAgent.mget(["myKey", "myKey2", "myKey3"]) == [
          "I♡HIP HOP",
          "こんにちは，世界",
          "call me stupid."
        ]
      )
    end

    test "with TTL" do
      assert(RedixAgent.set(:key, "call me stupid.", %{ttl: 300}) == "OK")
      assert(RedixAgent.get(:key) == "call me stupid.")
      assert(RedixAgent.ttl(:key) == 300)

      # use MULTI
      assert(
        Redix.transaction_pipeline!(RedixAgent.conn(), [
          ["SET", "myKey3", "foo"],
          ["EXPIRE", "myKey3", 200]
        ]) == ["OK", 1]
      )

      assert(RedixAgent.ttl("myKey3") == 200)
    end
  end

  describe "increment/decrement" do
    test "increment" do
      assert(RedixAgent.set(:key, 99) == "OK")
      assert(RedixAgent.get(:key) == "99")

      assert(RedixAgent.increment(:key) == 100)
      assert(RedixAgent.get(:key) == "100")

      assert(RedixAgent.increment(:key, 10) == 110)
      assert(RedixAgent.get(:key) == "110")
    end

    test "decrement" do
      assert(RedixAgent.set(:key, 99) == "OK")

      assert(RedixAgent.decrement(:key) == 98)
      assert(RedixAgent.get(:key) == "98")

      assert(RedixAgent.decrement(:key, 10) == 88)
      assert(RedixAgent.get(:key) == "88")
    end

    test "returns :invalid when not-integer value is given" do
      assert(RedixAgent.set(:key, 99) == "OK")

      assert(RedixAgent.increment(:key, "hoge") == :invalid)
      assert(RedixAgent.decrement(:key, "hoge") == :invalid)
    end
  end
end
