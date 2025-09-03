defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  @ejecutable_path Path.join(File.cwd!(), "ledger")
  @data_test_path "./test/data/test.csv"
  @data_test_csv "id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo\n12;1757600000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757610000;ETH;USDT;1.25;userL;;swap\n14;1757620000;BTC;;1500.00;userM;;alta_cuenta\n15;1757630000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757640000;BTC;BTC;0.30;userB;userC;transferencia"

  test "ledger transacciones con path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)
    {output, status} = System.cmd(@ejecutable_path, ["transacciones", "-t=#{@data_test_path}"])
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @data_test_csv |> String.split("\n", parts: 2) |> List.last()
    # trim_trailing elimina "\n" del final si es que esta, caso contrario devuelve el mismo string
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end
end
