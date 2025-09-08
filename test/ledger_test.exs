defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  @ejecutable_path Path.join(File.cwd!(), "ledger")
  @default_csv_path "./data/transacciones.csv"
  @transacciones_csv_test_path "./test/data/transacciones_test.csv"
  @transacciones_csv_test_data "id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo\n12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757620000;ETH;USDT;1.25;userL;;swap\n14;1757630000;BTC;;15.00;userM;;alta_cuenta\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia\n17;1757660000;USDT;USDT;200.00;userL;userM;transferencia"
  @delimitador_csv ";"
  @output_esperado_sin_flags "12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757620000;ETH;USDT;1.25;userL;;swap\n14;1757630000;BTC;;15.00;userM;;alta_cuenta\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia\n17;1757660000;USDT;USDT;200.00;userL;userM;transferencia"
  @output_path "./test/output.csv"

  def parsear_output(output, tipo_de_dato) do
    case tipo_de_dato do
      :map ->
        output
        |> String.trim()
        |> String.split("\n", trim: true)
        |> Enum.map(fn fila ->
          [moneda, monto] = String.split(fila, ";")
          {moneda, String.to_float(monto)}
        end)
        |> Map.new()

      :string ->
        String.trim_trailing(output, "\n")

      _ ->
        raise(ArgumentError,
          message: "Tipo de dato no implementado todavía para la función parsear_output"
        )
    end
  end

  test "ledger transacciones con path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {output, status} =
      System.cmd(@ejecutable_path, ["transacciones", "-t=#{@transacciones_csv_test_path}"])

    output_parseado = parsear_output(output, :string)
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @output_esperado_sin_flags
    # trim_trailing elimina "\n" del final si es que esta, caso contrario devuelve el mismo string
    assert output_parseado == esperado
  end

  test "ledger transacciones sin path" do
    esperado =
      File.stream!(@default_csv_path)
      |> CSV.decode!(separator: ?;)
      # Elimino la primer fila que son encabezados
      |> Stream.drop(1)
      |> Enum.map_join("\n", fn fila -> Enum.join(fila, @delimitador_csv) end)

    {output, status} = System.cmd(@ejecutable_path, ["transacciones"])

    output_parseado = parsear_output(output, :string)
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    assert output_parseado == esperado
  end

  @esperado_userA "12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia"
  test "ledger transacciones con cuenta origen" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@transacciones_csv_test_path}",
        "-c1=userA"
      ])

    output_parseado = parsear_output(output, :string)
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_userA
    assert output_parseado == esperado
  end

  @esperado_userA_to_userB "12;1757610000;USDT;ETH;50.00;userA;userB;transferencia"
  test "ledger transacciones con cuenta origen y cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@transacciones_csv_test_path}",
        "-c1=userA",
        "-c2=userB"
      ])

    output_parseado = parsear_output(output, :string)
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_userA_to_userB
    assert output_parseado == esperado
  end

  @esperado_cualquiera_to_userC "15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia"
  test "ledger transacciones con cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@transacciones_csv_test_path}",
        "-c2=userC"
      ])

    output_parseado = parsear_output(output, :string)
    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_cualquiera_to_userC
    assert output_parseado == esperado
  end

  test "ledger transacciones con output path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {_output, status} =
      System.cmd(@ejecutable_path, [
        "transacciones",
        "-t=#{@transacciones_csv_test_path}",
        "-o=#{@output_path}"
      ])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @output_esperado_sin_flags
    assert File.exists?(@output_path), "El programa no creo ningún archivo en el output esperado"
    output = File.read!(@output_path)
    output_parseado = parsear_output(output, :string)
    assert output_parseado == esperado
  end

  @esperado_balance_userM %{"BTC" => 15.000000, "USDT" => 200.000000}
  test "ledger balance sin output path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {output, status} =
      System.cmd(@ejecutable_path, [
        "balance",
        "-c1=userM",
        "-t=#{@transacciones_csv_test_path}"
      ])

    esperado = @esperado_balance_userM

    output_parseado = parsear_output(output, :map)

    assert output_parseado == esperado
  end

  test "ledger balance con output flag" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    {_output, status} =
      System.cmd(@ejecutable_path, [
        "balance",
        "-c1=userM",
        "-t=#{@transacciones_csv_test_path}",
        "-o=#{@output_path}"
      ])

    assert status == 0, "El exit code de ejecutar el programa no fue exitoso."
    esperado = @esperado_balance_userM
    assert File.exists?(@output_path), "El programa no creo ningún archivo en el output esperado"
    output = File.read!(@output_path)
    output_parseado = parsear_output(output, :map)

    assert output_parseado == esperado
  end
end
