defmodule Ledger.EntidadesTests do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Entidades
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
    Repo.delete_all(Transaccion)
    Repo.delete_all(Moneda)
    Repo.delete_all(Usuario)
    :ok
  end

  @nombre_default "juan"
  @nombre_alternativo "pedro"
  @fecha_nacimiento_default ~D[1990-01-01]
  @fecha_nacimiento_alternativa ~D[2000-01-01]
  @fecha_nacimiento_invalida ~D[2020-01-01]
  @moneda_default %{nombre: "ARS", precio_en_dolares: 1200}
  @moneda_alternativa %{nombre: "USD", precio_en_dolares: 1}
  @monto_default 100
  @monto_alternativo 200
  @tipo_default "transferencia"
  @tipo_alternativo "alta_cuenta"
  @descripcion_default "Pago de prueba"
  @descripcion_alternativa "Transferencia alternativa"
  @fecha_transaccion_default ~D[2024-01-01]
  @fecha_transaccion_alternativa ~D[2024-06-01]
  @campo_obligatorio "Este campo es obligatorio"
  @usuario_mayor_18 "El usuario debe ser mayor de 18 años"
  @monto_invalido -1
  @monto_negativo "Debe ser mayor a cero"

  describe "crear_usuario/2" do
    test "Ingreso usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(%{nombre: @nombre_default, fecha_nacimiento: @fecha_nacimiento_default})
      assert usuario_creado.nombre == @nombre_default
      assert usuario_creado.fecha_nacimiento == @fecha_nacimiento_default
    end

    test "Ingreso usuario inválido" do
      assert {:error, changeset} = Entidades.crear_usuario(%{})
      refute changeset.valid?

      assert %{nombre: [@campo_obligatorio], fecha_nacimiento: [@campo_obligatorio]} =
               FuncionesDB.errores_en(changeset)

      assert {:error, changeset} =
               Entidades.crear_usuario(%{nombre: @nombre_default, fecha_nacimiento: @fecha_nacimiento_invalida})

      refute changeset.valid?
      assert %{fecha_nacimiento: [@usuario_mayor_18]} = FuncionesDB.errores_en(changeset)
    end
  end

  describe "editar_usuario/2" do
    test "Edito usuario" do
      {:ok, usuario_creado} = Entidades.crear_usuario(%{nombre: @nombre_default, fecha_nacimiento: @fecha_nacimiento_default})
      atributos = %{nombre: @nombre_alternativo, fecha_nacimiento: @fecha_nacimiento_alternativa}
      {:ok, usuario_editado} = Entidades.editar_usuario(usuario_creado, atributos)
      assert usuario_editado.nombre == @nombre_alternativo
      assert usuario_editado.fecha_nacimiento == @fecha_nacimiento_alternativa
    end
  end

  describe "eliminar_usuario/1" do
    test "elimino usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(%{nombre: @nombre_default, fecha_nacimiento: @fecha_nacimiento_default})
      assert {:ok, usuario_eliminado} = Entidades.eliminar_usuario(usuario_creado.id)
      assert usuario_eliminado.id == usuario_creado.id
      assert Repo.get(Usuario, usuario_creado.id) == nil
    end

    test "elimino usuario inexistente en la base de datos" do
      id_usuario_falso = -1
      assert {:error, :not_found} = Entidades.eliminar_usuario(id_usuario_falso)
    end
  end

  describe "crear_transaccion/1" do
    test "creo transacción válida" do
      {:ok, usuario_origen} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      {:ok, usuario_destino} =
        Entidades.crear_usuario(%{
          nombre: @nombre_alternativo,
          fecha_nacimiento: @fecha_nacimiento_alternativa
        })

      moneda_origen =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      moneda_destino =
        %Moneda{}
        |> Moneda.changeset(@moneda_alternativa)
        |> Repo.insert!()

      atributos = %{
        monto: @monto_default,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: usuario_origen.id,
        cuenta_destino: usuario_destino.id
      }

      assert {:ok, transaccion_creada} = Entidades.crear_transaccion(atributos)

      assert transaccion_creada.monto == @monto_default
      assert transaccion_creada.tipo == @tipo_default
      assert transaccion_creada.moneda_origen_id == moneda_origen.id
      assert transaccion_creada.moneda_destino_id == moneda_destino.id
      assert transaccion_creada.cuenta_origen == usuario_origen.id
      assert transaccion_creada.cuenta_destino == usuario_destino.id
    end

    test "creo transacción inválida" do
      atributos = %{}

      assert {:error, changeset} = Entidades.crear_transaccion(atributos)
      refute changeset.valid?

      assert %{
        cuenta_origen: [@campo_obligatorio],
        moneda_origen_id: [@campo_obligatorio],
        monto: [@campo_obligatorio],
        tipo: [@campo_obligatorio]
      } = FuncionesDB.errores_en(changeset)
    end

    test "creo transacción con monto negativo" do
      {:ok, usuario_origen} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      moneda_origen =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      atributos = %{
        monto: @monto_invalido,
        tipo: @tipo_alternativo,
        moneda_origen_id: moneda_origen.id,
        cuenta_origen: usuario_origen.id
      }

      assert {:error, changeset} = Entidades.crear_transaccion(atributos)
      refute changeset.valid?
      assert %{monto: [@monto_negativo]} = FuncionesDB.errores_en(changeset)
    end
  end

  describe "deshacer_transaccion/1" do
    test "crea reversa válida para la última transacción" do
      {:ok, usuario_origen} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      {:ok, usuario_destino} =
        Entidades.crear_usuario(%{
          nombre: @nombre_alternativo,
          fecha_nacimiento: @fecha_nacimiento_alternativa
        })

      moneda_origen =
        %Moneda{}
        |> Moneda.changeset(@moneda_alternativa)
        |> Repo.insert!()

      moneda_destino =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      {:ok, original} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: usuario_origen.id,
          cuenta_destino: usuario_destino.id
        })

      assert {:ok, reversa} = Entidades.deshacer_transaccion(original.id)
      assert reversa.tipo == "reversa"
      assert reversa.monto == original.monto
      assert reversa.moneda_origen_id == original.moneda_destino_id
      assert reversa.moneda_destino_id == original.moneda_origen_id
      assert reversa.cuenta_origen == original.cuenta_destino
      assert reversa.cuenta_destino == original.cuenta_origen
    end

    test "devuelve error cuando la transacción no existe" do
      assert {:error, :not_found} = Entidades.deshacer_transaccion(-1)
    end

    test "rechaza deshacer si no es la última transacción" do
      {:ok, usuario_origen} =
        Entidades.crear_usuario(%{
          nombre: "carlos",
          fecha_nacimiento: @fecha_nacimiento_default
        })

      {:ok, usuario_destino} =
        Entidades.crear_usuario(%{
          nombre: "lucia",
          fecha_nacimiento: @fecha_nacimiento_alternativa
        })

      moneda_origen =
        %Moneda{}
        |> Moneda.changeset(@moneda_alternativa)
        |> Repo.insert!()

      moneda_destino =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      {:ok, primera_transaccion} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: usuario_origen.id,
          cuenta_destino: usuario_destino.id
        })

      {:ok, _segunda_transaccion} =
        Entidades.crear_transaccion(%{
          monto: @monto_alternativo,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: usuario_origen.id,
          cuenta_destino: usuario_destino.id
        })

      assert {:error, changeset} = Entidades.deshacer_transaccion(primera_transaccion.id)

      assert %{
               base: ["solo se puede deshacer la última transacción de cada cuenta involucrada"]
             } = FuncionesDB.errores_en(changeset)
    end
  end
end
