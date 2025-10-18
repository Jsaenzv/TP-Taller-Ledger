defmodule Ledger.ParserTest do
  use ExUnit.Case, async: true

  alias Ledger.Parser

  describe "parse_float/1" do
    test "raise cuando el valor es nil" do
      assert_raise ArgumentError, ~r/No se puede parsear el valor nil a float/, fn ->
        Parser.parse_float(nil)
      end
    end

    test "devuelve el mismo float cuando recibe un float" do
      assert Parser.parse_float(12.34) == 12.34
    end

    test "convierte un entero a float" do
      assert Parser.parse_float(42) == 42.0
    end

    test "parsea string con número válido" do
      assert Parser.parse_float("3.14159") == 3.14159
    end

    test "devuelve 0.0 cuando no puede parsear el string" do
      assert Parser.parse_float("abc") == 0.0
      assert Parser.parse_float("123abc") == 123.0
    end
  end

  describe "parsear_monto/1" do
    test "devuelve error cuando es nil" do
      assert {:error, "Monto ausente"} == Parser.parsear_monto(nil)
    end

    test "acepta float" do
      assert {:ok, 5.5} == Parser.parsear_monto(5.5)
    end

    test "convierte entero a float" do
      assert {:ok, 10.0} == Parser.parsear_monto(10)
    end

    test "parsea string válido no negativo" do
      assert {:ok, 123.45} == Parser.parsear_monto("123.45")
    end

    test "rechaza string negativo" do
      assert {:error, "Monto negativo no permitido"} == Parser.parsear_monto("-10.0")
    end

    test "rechaza string inválido" do
      assert {:error, "Monto inválido 'abc'"} == Parser.parsear_monto("abc")
      assert {:error, "Monto inválido '12abc'"} == Parser.parsear_monto("12abc")
    end
  end

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
