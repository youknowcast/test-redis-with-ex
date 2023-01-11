defmodule TestRedixTest do
  use ExUnit.Case
  doctest TestRedix

 setup_all do
   {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 26379)
   
   {:ok, conn: conn}
  end

  describe "String" do
    test "works", ctx do
      assert(Redix.command(ctx[:conn], ["SET", "myKey", "foo"]) == {:ok, "OK"})
      assert(Redix.command(ctx[:conn], ["GET", "myKey"]) == {:ok, "foo"})
    end
  end
end
