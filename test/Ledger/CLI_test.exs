defmodule CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Ledger.CLI
  alias Ledger.Repo
  alias Ledger.Entidades.{Usuario, Moneda, Transaccion}
  alias Ledger.Entidades

  @ejecutable_path Path.join(File.cwd!(), "ledger")
  @default_csv_path "./data/transacciones.csv"
  @transacciones_csv_test_path "./test/data/transacciones_test.csv"
  @transacciones_csv_test_data "id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo\n1;1757610001;USDT;;400.00;userA;;alta_cuenta\n2;1757610002;BTC;;1;userB;;alta_cuenta\n3;1757610003;ETH;;1.25;userL;;alta_cuenta\n4;1757630004;BTC;;15.00;userM;;alta_cuenta\n14;1757630000;ETH;;3.00;userC;;alta_cuenta\n12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757620000;ETH;USDT;1.25;userL;;swap\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia\n17;1757660000;USDT;USDT;200.00;userL;userM;transferencia"
  @delimitador_csv ";"
  @output_esperado_sin_flags "1;1757610001;USDT;;400.00;userA;;alta_cuenta\n2;1757610002;BTC;;1;userB;;alta_cuenta\n3;1757610003;ETH;;1.25;userL;;alta_cuenta\n4;1757630004;BTC;;15.00;userM;;alta_cuenta\n14;1757630000;ETH;;3.00;userC;;alta_cuenta\n12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n13;1757620000;ETH;USDT;1.25;userL;;swap\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia\n17;1757660000;USDT;USDT;200.00;userL;userM;transferencia"
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

    output =
      capture_io(fn ->
        assert :ok == Ledger.CLI.main(["transacciones", "-t=#{@transacciones_csv_test_path}"])
      end)

    output_parseado = parsear_output(output, :string)
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

    output =
      capture_io(fn ->
        assert :ok == Ledger.CLI.main(["transacciones"])
      end)

    output_parseado = parsear_output(output, :string)
    assert output_parseado == esperado
  end

  @esperado_userA "1;1757610001;USDT;;400.00;userA;;alta_cuenta\n12;1757610000;USDT;ETH;50.00;userA;userB;transferencia\n15;1757640000;USDT;BTC;200.00;userA;userC;transferencia"
  test "ledger transacciones con cuenta origen" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    output =
      capture_io(fn ->
        assert :ok ==
                 Ledger.CLI.main([
                   "transacciones",
                   "-t=#{@transacciones_csv_test_path}",
                   "-c1=userA"
                 ])
      end)

    output_parseado = parsear_output(output, :string)
    esperado = @esperado_userA
    assert output_parseado == esperado
  end

  @esperado_userA_to_userB "12;1757610000;USDT;ETH;50.00;userA;userB;transferencia"
  test "ledger transacciones con cuenta origen y cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    output =
      capture_io(fn ->
        assert :ok ==
                 Ledger.CLI.main([
                   "transacciones",
                   "-t=#{@transacciones_csv_test_path}",
                   "-c1=userA",
                   "-c2=userB"
                 ])
      end)

    output_parseado = parsear_output(output, :string)
    esperado = @esperado_userA_to_userB
    assert output_parseado == esperado
  end

  @esperado_cualquiera_to_userC "15;1757640000;USDT;BTC;200.00;userA;userC;transferencia\n16;1757650000;BTC;BTC;0.30;userB;userC;transferencia"
  test "ledger transacciones con cuenta destino" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    output =
      capture_io(fn ->
        assert :ok ==
                 Ledger.CLI.main([
                   "transacciones",
                   "-t=#{@transacciones_csv_test_path}",
                   "-c2=userC"
                 ])
      end)

    output_parseado = parsear_output(output, :string)
    esperado = @esperado_cualquiera_to_userC
    assert output_parseado == esperado
  end

  test "ledger transacciones con output path" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    capture_io(fn ->
      assert :ok ==
               Ledger.CLI.main([
                 "transacciones",
                 "-t=#{@transacciones_csv_test_path}",
                 "-o=#{@output_path}"
               ])
    end)

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

    output =
      capture_io(fn ->
        assert :ok ==
                 Ledger.CLI.main([
                   "balance",
                   "-c1=userM",
                   "-t=#{@transacciones_csv_test_path}"
                 ])
      end)

    esperado = @esperado_balance_userM

    output_parseado = parsear_output(output, :map)

    assert output_parseado == esperado
  end

  test "ledger balance con output flag" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    capture_io(fn ->
      assert :ok ==
               Ledger.CLI.main([
                 "balance",
                 "-c1=userM",
                 "-t=#{@transacciones_csv_test_path}",
                 "-o=#{@output_path}"
               ])
    end)

    esperado = @esperado_balance_userM
    assert File.exists?(@output_path), "El programa no creo ningún archivo en el output esperado"
    output = File.read!(@output_path)
    output_parseado = parsear_output(output, :map)

    assert output_parseado == esperado
  end

  @esperado_balance_userC_convertido_USDT %{"USDT" => 29900.00}
  test "ledger balance con conversión de moneda" do
    assert File.exists?(@ejecutable_path), "Compila el escript con: mix escript.build"
    File.write!(@transacciones_csv_test_path, @transacciones_csv_test_data)

    output =
      capture_io(fn ->
        assert :ok ==
                 Ledger.CLI.main([
                   "balance",
                   "-c1=userC",
                   "-t=#{@transacciones_csv_test_path}",
                   "-m=USDT"
                 ])
      end)

    esperado = @esperado_balance_userC_convertido_USDT

    output_parseado = parsear_output(output, :map)

    assert output_parseado == esperado
  end

  describe "CLI crear_usuario" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Usuario)
      :ok
    end

    test "crea un usuario cuando los flags son válidos" do
      assert {:ok, usuario} =
               Ledger.CLI.main(["crear_usuario", "-n=ana", "-b=1990-01-01"])

      assert usuario.nombre == "ana"
      assert usuario.fecha_nacimiento == ~D[1990-01-01]
      assert Repo.get!(Usuario, usuario.id)
    end

    test "raise cuando falta un flag obligatorio" do
      assert_raise RuntimeError, ~r/Error al válidar los flags/, fn ->
        Ledger.CLI.main(["crear_usuario", "-b=1990-01-01"])
      end
    end
  end

  describe "CLI editar_usuario" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Usuario)
      :ok
    end

    test "edita usuario válido" do
      atributos_usuario = %{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]}
      {:ok, usuario} = Entidades.crear_usuario(atributos_usuario)

      assert {:ok, usuario_editado} =
               Ledger.CLI.main(["editar_usuario", "-u=#{usuario.id}", "-n=pedro"])

      assert usuario_editado.nombre == "pedro"
      assert usuario_editado.fecha_nacimiento == usuario.fecha_nacimiento
      assert usuario_editado.id == usuario.id
    end

    test "error al editar usuario inexistente" do
      assert {:error, :not_found} == Ledger.CLI.main(["editar_usuario", "-u=999999", "-n=pedro"])
    end
  end

  describe "CLI eliminar_usuario" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Usuario)
      :ok
    end

    test "elimino usuario válido" do
      atributos_usuario = %{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]}
      {:ok, usuario} = Entidades.crear_usuario(atributos_usuario)

      assert {:ok, usuario_eliminado} =
               Ledger.CLI.main(["eliminar_usuario", "-u=#{usuario.id}"])

      assert usuario_eliminado.nombre == usuario.nombre
      assert usuario_eliminado.fecha_nacimiento == usuario.fecha_nacimiento
      assert usuario_eliminado.id == usuario.id
    end

    test "elimino usuario no existente" do
      assert {:error, :not_found} == Ledger.CLI.main(["eliminar_usuario", "-u=999999"])
    end
  end

  describe "CLI ver_usuario" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Usuario)
      :ok
    end

    test "ver_usuario válido" do
      atributos_usuario = %{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]}
      {:ok, usuario} = Entidades.crear_usuario(atributos_usuario)

      output =
        capture_io(fn ->
          assert :ok == Ledger.CLI.main(["ver_usuario", "-u=#{usuario.id}"])
        end)

      assert output =~ "Usuario:"
      assert output =~ "  id: #{usuario.id}"
      assert output =~ "  nombre: #{usuario.nombre}"
      assert output =~ "  fecha_nacimiento: #{usuario.fecha_nacimiento}"
      assert output =~ "  creado_el:"
      assert output =~ "  actualizado_el:"
    end

    test "ver_usuario con id inexistente" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["ver_usuario", "-u=999999"])
        end)

      assert output =~ "Usuario no encontrado"
    end
  end

  describe "CLI crear_moneda" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Moneda)
      :ok
    end

    test "crea una moneda cuando los flags son válidos" do
      assert {:ok, moneda} =
               Ledger.CLI.main(["crear_moneda", "-n=ARS", "-p=1200"])

      assert moneda.nombre == "ARS"
      assert moneda.precio_en_dolares == 1200
      assert Repo.get!(Moneda, moneda.id)
    end

    test "raise cuando falta un flag obligatorio" do
      assert_raise RuntimeError, ~r/Error al válidar los flags/, fn ->
        Ledger.CLI.main(["crear_moneda", "-n=ARS"])
      end
    end
  end

  describe "CLI editar_moneda" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Moneda)
      :ok
    end

    test "edita moneda válida" do
      atributos_moneda = %{nombre: "ARS", precio_en_dolares: 1200}
      {:ok, moneda} = Entidades.crear_moneda(atributos_moneda)

      assert {:ok, moneda_editada} =
               Ledger.CLI.main(["editar_moneda", "-id=#{moneda.id}", "-p=1500"])

      assert moneda_editada.id == moneda.id
      assert moneda_editada.nombre == moneda.nombre
      assert moneda_editada.precio_en_dolares == 1500
    end

    test "error al editar moneda inexistente" do
      assert {:error, :not_found} == Ledger.CLI.main(["editar_moneda", "-id=999999", "-p=1500"])
    end

    test "error al faltar flag obligatorio" do
      atributos_moneda = %{nombre: "ARS", precio_en_dolares: 1200}
      {:ok, moneda} = Entidades.crear_moneda(atributos_moneda)

      assert_raise RuntimeError, ~r/Error al válidar los flags/, fn ->
        Ledger.CLI.main(["editar_moneda", "-id=#{moneda.id}"])
      end
    end
  end

  describe "CLI ver_moneda" do

    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Moneda)
      :ok
    end

    test "ver_moneda válida" do
      atributos_moneda = %{nombre: "ARS", precio_en_dolares: 1200}
      {:ok, moneda} = Entidades.crear_moneda(atributos_moneda)

      output =
        capture_io(fn ->
          assert :ok == Ledger.CLI.main(["ver_moneda", "-id=#{moneda.id}"])
        end)

      assert output =~ "Moneda:"
      assert output =~ "  id: #{moneda.id}"
      assert output =~ "  nombre: #{moneda.nombre}"
      assert output =~ "  precio_en_dolares: 1200.000000"
      assert output =~ "  creado_el:"
      assert output =~ "  actualizado_el:"
    end

    test "ver_moneda inexistente" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["ver_moneda", "-id=999999"])
        end)

      assert output =~ "Moneda no encontrada"
    end
  end

  describe "CLI alta_cuenta" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
      Repo.delete_all(Transaccion)
      Repo.delete_all(Moneda)
      Repo.delete_all(Usuario)
      :ok
    end

    test "creo transacción válida" do
      {:ok, usuario} = Ledger.CLI.main(["crear_usuario", "-n=juan", "-b=1990-01-01"])
      {:ok, moneda} = Ledger.CLI.main(["crear_moneda", "-n=ARS", "-p=1200"])
      {:ok, transaccion} = Ledger.CLI.main(["alta_cuenta", "-u=#{usuario.id}", "-m=#{moneda.id}", "-a=10000"])

      assert transaccion.tipo == "alta_cuenta"
      assert transaccion.monto == 10_000.0
      assert transaccion.moneda_origen_id == moneda.id
      assert transaccion.cuenta_origen == usuario.id
      assert is_nil(transaccion.moneda_destino_id)
      assert is_nil(transaccion.cuenta_destino)

      insertada = Repo.get!(Transaccion, transaccion.id)
      assert insertada.id == transaccion.id
    end

    test "falla cuando falta flag obligatorio" do
      {:ok, usuario} = Ledger.CLI.main(["crear_usuario", "-n=juan", "-b=1990-01-01"])
      {:ok, moneda} = Ledger.CLI.main(["crear_moneda", "-n=ARS", "-p=1200"])

      assert_raise RuntimeError, ~r/Error al validar los flags/, fn ->
        Ledger.CLI.main(["alta_cuenta", "-u=#{usuario.id}", "-m=#{moneda.id}"])
      end
    end

    test "falla cuando el usuario no existe" do
      {:ok, moneda} = Ledger.CLI.main(["crear_moneda", "-n=ARS", "-p=1200"])

      assert {:error, %Ecto.Changeset{} = changeset} =
               Ledger.CLI.main(["alta_cuenta", "-u=999999", "-m=#{moneda.id}", "-a=10000"])

      assert {:cuenta_origen_usuario, {"Debe existir en la tabla Usuarios", _}} =
               List.keyfind(changeset.errors, :cuenta_origen_usuario, 0)
    end

    test "falla cuando el monto es negativo" do
      {:ok, usuario} = Ledger.CLI.main(["crear_usuario", "-n=juan", "-b=1990-01-01"])
      {:ok, moneda} = Ledger.CLI.main(["crear_moneda", "-n=ARS", "-p=1200"])

      assert {:error, %Ecto.Changeset{} = changeset} =
               Ledger.CLI.main(["alta_cuenta", "-u=#{usuario.id}", "-m=#{moneda.id}", "-a=-10"])

      assert {:monto, {"Debe ser mayor a cero", _}} = List.keyfind(changeset.errors, :monto, 0)
    end
  end
end
