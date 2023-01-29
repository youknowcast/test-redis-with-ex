defmodule TestClusterTest do
  use ExUnit.Case

  alias TestRedix.RedixAgent

  setup do
    RedixAgent.start_link("127.0.0.1", 36379)

    {:ok, %{}}
  end

  @tag :skip
  test "works" do
    RedixAgent.set(:foo, :bar)
    assert(RedixAgent.get(:foo) == "bar")
  end

  @tag :skip
  test "works with mset" do
    assert(
      RedixAgent.mset(
        myKey: "I♡HIP HOP",
        myKey2: "こんにちは，世界",
        myKey3: "call me stupid.",
        hoge: "foo",
        moge: "bar",
        page: "baz"
      ) == "OK"
    )

    assert(RedixAgent.get("myKey") == "I♡HIP HOP")
    assert(RedixAgent.get("myKey2") == "こんにちは，世界")
    assert(RedixAgent.get("myKey3") == "call me stupid.")
    assert(RedixAgent.get("hoge") == "foo")
    assert(RedixAgent.get("moge") == "bar")
    assert(RedixAgent.get("page") == "baz")
  end
end
