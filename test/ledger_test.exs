defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  @ejecutable_path Path.join(File.cwd!(), "ledger")
  @default_csv_path "./data/transacciones.csv"
  @data_test_path "./test/data/test.csv"
  @data_test_csv "id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo\n12;1757600000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757610000;ETH;USDT;1.25;userL;;swap\n14;1757620000;BTC;;1500.00;userM;;alta_cuenta\n15;1757630000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757640000;BTC;BTC;0.30;userB;userC;transferencia"
  @delimitador_csv ";"
  @output_esperado_sin_flags "12;1757600000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757610000;ETH;USDT;1.25;userL;;swap\n14;1757620000;BTC;;1500.00;userM;;alta_cuenta\n15;1757630000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757640000;BTC;BTC;0.30;userB;userC;transferencia"

  test "ledger transacciones con path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)
    {output, status} = System.cmd(@ejecutable_path, ["transacciones", "-t=#{@data_test_path}"])
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @output_esperado_sin_flags
    # trim_trailing elimina "\n" del final si es que esta, caso contrario devuelve el mismo string
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end

  test "ledger transacciones sin path" do
    esperado =
      File.stream!(@default_csv_path)
      |> CSV.decode!(separator: ?;)
      # Elimino la primer fila que son encabezados
      |> Stream.drop(1)
      |> Enum.map_join("\n", fn fila -> Enum.join(fila, @delimitador_csv) end)

    {output, status} = System.cmd(@ejecutable_path, ["transacciones"])
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end

  @esperado_userA "12;1757600000;USDT;ETH;50.00;userA;userB;transferencia\n15;1757630000;USDT;BTC;200.00;userA;userC;transferencia"
  test "ledger transacciones con cuenta origen" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)

    {output, status} =
      System.cmd(@ejecutable_path, ["transacciones", "-t=#{@data_test_path}", "-c1=userA"])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_userA
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end

  @esperado_userA_to_userB "12;1757600000;USDT;ETH;50.00;userA;userB;transferencia"
  test "ledger transacciones con cuenta origen y cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)

    {output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@data_test_path}",
        "-c1=userA",
        "-c2=userB"
      ])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_userA_to_userB
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end

  @esperado_cualquiera_to_userC "15;1757630000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757640000;BTC;BTC;0.30;userB;userC;transferencia"
  test "ledger transacciones con cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)

    {output, status} =
      System.cmd(@ejecutable_path, ["transacciones", "-t=#{@data_test_path}", "-c2=userC"])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_cualquiera_to_userC
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end

  @output_path "./test/output.csv"
  test "ledger transacciones con output path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@data_test_path, @data_test_csv)

    {_output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@data_test_path}",
        "-o=#{@output_path}"
      ])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @output_esperado_sin_flags
    assert File.exists?(@output_path), "El programa no creo ningún archivo en el output esperado"
    output = File.read!(@output_path)
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n")
  end
end
