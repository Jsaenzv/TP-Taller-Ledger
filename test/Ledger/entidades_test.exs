defmodule Ledger.EntidadesTests do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Entidades
  alias Ledger.Repo

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
  @monto_default "100"
  @monto_alternativo "200"
  @tipo_default "transferencia"
  @tipo_alternativo "alta_cuenta"
  @campo_obligatorio "Este campo es obligatorio"
  @usuario_mayor_18 "El usuario debe ser mayor de 18 años"
  @monto_invalido -1
  @monto_negativo "Debe ser mayor a cero"

  describe "crear_usuario/2" do
    test "Ingreso usuario válido" do
      {:ok, usuario_creado} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      assert usuario_creado.nombre == @nombre_default
      assert usuario_creado.fecha_nacimiento == @fecha_nacimiento_default
    end

    test "Ingreso usuario inválido" do
      assert {:error, changeset} = Entidades.crear_usuario(%{})
      refute changeset.valid?

      assert %{nombre: [@campo_obligatorio], fecha_nacimiento: [@campo_obligatorio]} =
               FuncionesDB.errores_en(changeset)

      assert {:error, changeset} =
               Entidades.crear_usuario(%{
                 nombre: @nombre_default,
                 fecha_nacimiento: @fecha_nacimiento_invalida
               })

      refute changeset.valid?
      assert %{fecha_nacimiento: [@usuario_mayor_18]} = FuncionesDB.errores_en(changeset)
    end
  end

  describe "editar_usuario/2" do
    test "Edito usuario" do
      {:ok, usuario_creado} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      atributos = %{nombre: @nombre_alternativo, fecha_nacimiento: @fecha_nacimiento_alternativa}
      {:ok, usuario_editado} = Entidades.editar_usuario(usuario_creado.id, atributos)
      assert usuario_editado.nombre == @nombre_alternativo
      assert usuario_editado.fecha_nacimiento == @fecha_nacimiento_alternativa
    end
  end

  describe "eliminar_usuario/1" do
    test "elimino usuario válido" do
      {:ok, usuario_creado} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })

      assert {:ok, usuario_eliminado} = Entidades.eliminar_usuario(usuario_creado.id)
      assert usuario_eliminado.id == usuario_creado.id
      assert Repo.get(Usuario, usuario_creado.id) == nil
    end

    test "elimino usuario inexistente en la base de datos" do
      id_usuario_falso = -1
      assert {:error, :not_found} = Entidades.eliminar_usuario(id_usuario_falso)
    end
  end

  describe "crear_moneda/1" do
    test "creo moneda válida" do
      assert {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      assert moneda.nombre == @moneda_default.nombre
      assert moneda.precio_en_dolares == @moneda_default.precio_en_dolares
    end

    test "creo moneda inválida" do
      assert {:error, changeset} = Entidades.crear_moneda(%{})
      refute changeset.valid?

      assert %{
               nombre: [@campo_obligatorio],
               precio_en_dolares: [@campo_obligatorio]
             } = FuncionesDB.errores_en(changeset)
    end
  end

  describe "editar_moneda/2" do
    test "actualiza precio en dólares" do
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)

      assert {:ok, moneda_editada} = Entidades.editar_moneda(moneda, 1500.0)
      assert moneda_editada.precio_en_dolares == 1500.0
      assert moneda_editada.nombre == moneda.nombre
    end
  end

  describe "eliminar_moneda/1" do
    test "elimino moneda existente" do
      {:ok, moneda} = Entidades.crear_moneda(@moneda_alternativa)

      assert {:ok, moneda_eliminada} = Entidades.eliminar_moneda(moneda.id)
      assert moneda_eliminada.id == moneda.id
      assert Repo.get(Moneda, moneda.id) == nil
    end

    test "retorna error cuando la moneda no existe" do
      assert {:error, :not_found} = Entidades.eliminar_moneda(-1)
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

      moneda =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_origen.id
        })

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_destino.id
        })

      atributos = %{
        monto: @monto_default,
        tipo: @tipo_default,
        moneda_origen_id: moneda.id,
        moneda_destino_id: moneda.id,
        cuenta_origen: usuario_origen.id,
        cuenta_destino: usuario_destino.id
      }

      assert {:ok, transaccion_creada} = Entidades.crear_transaccion(atributos)

      assert transaccion_creada.tipo == @tipo_default
      assert transaccion_creada.moneda_origen_id == moneda.id
    end

    test "creo transacción inválida" do
      atributos = %{}

      assert {:error, changeset} = Entidades.crear_transaccion(atributos)
      refute changeset.valid?

      assert %{
               cuenta_origen_id: [@campo_obligatorio],
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

      moneda =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_origen.id
        })

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_destino.id
        })

      atributos = %{
        monto: @monto_default,
        tipo: @tipo_default,
        moneda_origen_id: moneda.id,
        moneda_destino_id: moneda.id,
        cuenta_origen: usuario_origen.id,
        cuenta_destino: usuario_destino.id
      }

      {:ok, original} = Entidades.crear_transaccion(atributos)

      assert {:ok, reversa} = Entidades.deshacer_transaccion(original.id)
      assert reversa.tipo == "reversa"
      assert reversa.monto == original.monto
      assert reversa.moneda_origen_id == original.moneda_destino_id
      assert reversa.moneda_destino_id == original.moneda_origen_id
      assert reversa.cuenta_origen_id == original.cuenta_destino_id
      assert reversa.cuenta_destino_id == original.cuenta_origen_id
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

      moneda =
        %Moneda{}
        |> Moneda.changeset(@moneda_default)
        |> Repo.insert!()

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: 1_000_000,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_origen.id
        })

      {:ok, _} =
        Entidades.crear_transaccion(%{
          monto: 1_000_000,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario_destino.id
        })

      atributos = %{
        monto: @monto_default,
        tipo: @tipo_default,
        moneda_origen_id: moneda.id,
        moneda_destino_id: moneda.id,
        cuenta_origen: usuario_origen.id,
        cuenta_destino: usuario_destino.id
      }

      {:ok, primera_transaccion} = Entidades.crear_transaccion(atributos)
      {:ok, segunda_transaccion} = Entidades.crear_transaccion(atributos)

      assert {:error, changeset} = Entidades.deshacer_transaccion(primera_transaccion.id)

      assert %{
               base: ["solo se puede deshacer la última transacción de cada cuenta involucrada"]
             } = FuncionesDB.errores_en(changeset)
    end
  end
end
