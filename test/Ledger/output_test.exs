defmodule Ledger.OutputTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Ledger.Output
  alias Ledger.Formatter
  alias Ledger.Entidades
  alias Ledger.Entidades.{Cuenta, Moneda, Transaccion, Usuario}
  alias Ledger.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    Repo.delete_all(Transaccion)
    Repo.delete_all(Cuenta)
    Repo.delete_all(Moneda)
    Repo.delete_all(Usuario)
    :ok
  end

  describe "output_transacciones/1" do
    test "imprime mensaje cuando no hay transacciones" do
      assert capture_io(fn -> Output.output_transacciones([]) end) == "No hay transacciones\n"
    end

    test "imprime cada transaccion formateada" do
      transaccion =
        struct(Transaccion,
          id: 1,
          cuenta_origen_id: 10,
          moneda_origen_id: 20,
          tipo: "alta_cuenta",
          monto: 100.0,
          inserted_at: ~N[2020-01-01 00:00:00],
          updated_at: ~N[2020-01-02 00:00:00]
        )

      esperado = Formatter.formattear_transaccion(transaccion)

      assert capture_io(fn ->
               Output.output_transacciones([transaccion])
             end) == esperado <> "\n"
    end
  end

  describe "output_balance/1" do
    test "imprime balances formateados" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{nombre: "Maria", fecha_nacimiento: ~D[1990-01-01]})

      {:ok, moneda} = Entidades.crear_moneda(%{nombre: "ARS", precio_en_dolares: 1200.0})

      {:ok, cuenta} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario.id,
          moneda_id: moneda.id,
          balance: 123.456
        })

      esperado = Formatter.formattear_balance([cuenta])

      assert capture_io(fn ->
               Output.output_balance([cuenta])
             end) == esperado <> "\n"
    end
  end

  describe "output_ver_usuario/1" do
    test "avisa cuando no encuentra usuario" do
      assert capture_io(fn -> Output.output_ver_usuario(nil) end) == "Usuario no encontrado\n"
    end

    test "imprime usuario formateado" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{nombre: "Lucia", fecha_nacimiento: ~D[1988-05-05]})

      esperado = Formatter.formattear_usuario(usuario)

      assert capture_io(fn ->
               Output.output_ver_usuario(usuario)
             end) == esperado <> "\n"
    end
  end

  describe "output_ver_moneda/1" do
    test "avisa cuando no encuentra moneda" do
      assert capture_io(fn -> Output.output_ver_moneda(-1) end) == "Moneda no encontrada\n"
    end

    test "imprime la moneda formateada" do
      {:ok, moneda} = Entidades.crear_moneda(%{nombre: "USD", precio_en_dolares: 1.0})
      esperado = Formatter.formatear_moneda(moneda)

      assert capture_io(fn ->
               Output.output_ver_moneda(moneda.id)
             end) == esperado <> "\n"
    end
  end

  describe "output_ver_transaccion/1" do
    test "avisa cuando no encuentra transaccion" do
      assert capture_io(fn -> Output.output_ver_transaccion(-1) end) ==
               "Transacción no encontrada\n"
    end

    test "imprime la transaccion formateada" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{nombre: "Juan", fecha_nacimiento: ~D[1990-01-01]})

      {:ok, moneda} = Entidades.crear_moneda(%{nombre: "BRL", precio_en_dolares: 0.25})

      {:ok, transaccion_creada} =
        Entidades.crear_transaccion(%{
          monto: "100",
          tipo: "alta_cuenta",
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario.id
        })

      transaccion = Entidades.obtener_transaccion(transaccion_creada.id)
      esperado = Formatter.formattear_transaccion(transaccion)

      assert capture_io(fn ->
               Output.output_ver_transaccion(transaccion.id)
             end) == esperado <> "\n"
    end
  end
end
