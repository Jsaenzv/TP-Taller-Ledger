defmodule Ledger.CSVTest do
  use ExUnit.Case, async: true

  alias Ledger.CSV

  describe "leer_csv/2" do
    test "devuelve {:ok, filas} cuando el archivo existe" do
      path = Path.join("test/tmp", "sample.csv")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "col1;col2\n1;2\n3;4\n")

      assert {:ok, [%{"col1" => "1", "col2" => "2"}, %{"col1" => "3", "col2" => "4"}]} ==
               CSV.leer_csv(path, ["col1", "col2"])
    end

    test "devuelve {:error, mensaje} cuando el archivo no existe" do
      path = "test/tmp/no_existe.csv"
      assert {:error, "Archivo no encontrado: #{path}"} == CSV.leer_csv(path, ["col1"])
    end
  end

  describe "obtener_tipos_de_cambio/1" do
    test "devuelve un mapa con moneda => float" do
      path = Path.join("test/tmp", "monedas.csv")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "moneda;cambio\nUSD;1.0\nARS;0.001\n")

      assert %{"USD" => 1.0, "ARS" => 0.001} == CSV.obtener_tipos_de_cambio(path)
    end

    test "lanza error si el archivo no existe" do
      assert_raise RuntimeError, ~r/Archivo no encontrado:/, fn ->
        CSV.obtener_tipos_de_cambio("test/tmp/no_monedas.csv")
      end
    end
  end

  describe "obtener_transacciones/1" do
    test "devuelve lista de transacciones" do
      path = Path.join("test/tmp", "transacciones.csv")
      File.mkdir_p!(Path.dirname(path))

      contenido =
        "id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo\n" <>
          "1;123;USD;ARS;100;userA;userB;transferencia\n"

      File.write!(path, contenido)

      assert [
               %{
                 "id" => "1",
                 "timestamp" => "123",
                 "moneda_origen" => "USD",
                 "moneda_destino" => "ARS",
                 "monto" => "100",
                 "cuenta_origen" => "userA",
                 "cuenta_destino" => "userB",
                 "tipo" => "transferencia"
               }
             ] == CSV.obtener_transacciones(path)
    end

    test "lanza error si el archivo no existe" do
      assert_raise RuntimeError, ~r/Archivo no encontrado:/, fn ->
        CSV.obtener_transacciones("test/tmp/no_transacciones.csv")
      end
    end
  end
end
