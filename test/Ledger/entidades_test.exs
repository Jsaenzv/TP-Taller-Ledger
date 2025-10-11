defmodule Ledger.EntidadesTests do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Entidades
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
    Repo.delete_all(Usuario)
    :ok
  end

  @nombre_default "juan"
  @nombre_alternativo "pedro"
  @fecha_nacimiento_default ~D[1990-01-01]
  @fecha_nacimiento_alternativa ~D[2000-01-01]
  @fecha_nacimiento_invalida ~D[2020-01-01]
  @moneda_default %Moneda{nombre: "Peso", simbolo: "ARS"}
  @moneda_alternativa %Moneda{nombre: "Dólar", simbolo: "USD"}

  @monto_default 100
  @monto_alternativo 200

  @descripcion_default "Pago de prueba"
  @descripcion_alternativa "Transferencia alternativa"

  @fecha_transaccion_default ~D[2024-01-01]
  @fecha_transaccion_alternativa ~D[2024-06-01]

  @campo_obligatorio "Este campo es obligatorio"
  @usuario_mayor_18 "El usuario debe ser mayor de 18 años"
  @monto_negativo "Debe ser mayor que 0"

  describe "crear_usuario/2" do
    test "Ingreso usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      assert usuario_creado.nombre == @nombre_default
      assert usuario_creado.fecha_nacimiento == @fecha_nacimiento_default
    end

    test "Ingreso usuario inválido" do
      assert {:error, changeset} = Entidades.crear_usuario(nil, nil)
      refute changeset.valid?

      assert %{nombre: [@campo_obligatorio], fecha_nacimiento: [@campo_obligatorio]} =
               FuncionesDB.errores_en(changeset)

      assert {:error, changeset} =
               Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_invalida)

      refute changeset.valid?
      assert %{fecha_nacimiento: [@usuario_mayor_18]} = FuncionesDB.errores_en(changeset)
    end
  end

  describe "editar_usuario/2" do
    test "Edito usuario" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      atributos = %{nombre: @nombre_alternativo, fecha_nacimiento: @fecha_nacimiento_alternativa}
      {:ok, usuario_editado} = Entidades.editar_usuario(usuario_creado, atributos)
      assert usuario_editado.nombre == @nombre_alternativo
      assert usuario_editado.fecha_nacimiento == @fecha_nacimiento_alternativa
    end
  end

  describe "eliminar_usuario/1" do
    test "elimino usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      assert {:ok, usuario_eliminado} = Entidades.eliminar_usuario(usuario_creado)
      assert usuario_eliminado.id == usuario_creado.id
      assert Repo.get(Usuario, usuario_creado.id) == nil
    end

    test "elimino usuario inexistente en la base de datos" do
      usuario_falso = %Usuario{id: -1, nombre: "fantasma", fecha_nacimiento: ~D[1980-01-01]}
      assert {:error, :not_found} = Entidades.eliminar_usuario(usuario_falso)
    end
  end

  describe "crear_transaccion/6" do
    test "creo transacción válida" do
      {:ok, usuario_origen} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)

      {:ok, usuario_destino} =
        Entidades.crear_usuario(@nombre_alternativo, @fecha_nacimiento_alternativa)

      moneda = @moneda_default
      monto = @monto_default
      descripcion = @descripcion_default
      fecha = @fecha_transaccion_default

      {:ok, transaccion_creada} =
        Entidades.crear_transaccion(
          usuario_origen,
          usuario_destino,
          moneda,
          monto,
          descripcion,
          fecha
        )

      assert transaccion_creada.usuario_origen_id == usuario_origen.id
      assert transaccion_creada.usuario_destino_id == usuario_destino.id
      assert transaccion_creada.moneda_id == moneda.id
      assert transaccion_creada.monto == monto
      assert transaccion_creada.descripcion == descripcion
      assert transaccion_creada.fecha == fecha
    end

    test "creo transacción inválida" do
      usuario_origen = nil
      usuario_destino = nil
      moneda = nil
      monto = -10
      descripcion = nil
      fecha = nil

      assert {:error, changeset} =
               Entidades.crear_transaccion(
                 usuario_origen,
                 usuario_destino,
                 moneda,
                 monto,
                 descripcion,
                 fecha
               )

      refute changeset.valid?

      assert %{
               usuario_origen_id: [@campo_obligatorio],
               usuario_destino_id: [@campo_obligatorio],
               moneda_id: [@campo_obligatorio],
               monto: [@monto_negativo],
               descripcion: [@campo_obligatorio],
               fecha: [@campo_obligatorio]
             } = FuncionesDB.errores_en(changeset)
    end
  end
end
