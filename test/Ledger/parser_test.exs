defmodule Ledger.ParserTest do
  use ExUnit.Case, async: true
  alias Ledger.Parser

  describe "parsear_flags/1" do
    test "parsea flags válidos" do
      flags = ["-u=1", "-a=100.0", "-m=USD"]

      assert Parser.parsear_flags(flags) == %{
               "id_usuario" => "1",
               "monto" => "100.0",
               "moneda" => "USD"
             }
    end

    test "levanta error para flag no soportado" do
      assert_raise ArgumentError, ~r/Flag no soportado: -x/, fn ->
        Parser.parsear_flags(["-x=valor"])
      end
    end
  end
end
