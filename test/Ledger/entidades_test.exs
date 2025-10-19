defmodule Ledger.EntidadesTests do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Cuenta, Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Entidades
  alias Ledger.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
    Repo.delete_all(Transaccion)
    Repo.delete_all(Moneda)
    Repo.delete_all(Usuario)
    Repo.delete_all(Cuenta)
    :ok
  end

  @nombre_default "juan"
  @nombre_alternativo "pedro"
  @nombre_tercero "maria"
  @fecha_nacimiento_default ~D[1990-01-01]
  @fecha_nacimiento_alternativa ~D[2000-01-01]
  @fecha_nacimiento_invalida ~D[2020-01-01]
  @moneda_default %{nombre: "ARS", precio_en_dolares: 1200}
  @moneda_alternativa %{nombre: "USD", precio_en_dolares: 1}
  @moneda_tercera %{nombre: "BRL", precio_en_dolares: 0.25}
  @monto_default "100"
  @monto_alternativo "200"
  @tipo_default "transferencia"
  @tipo_alternativo "alta_cuenta"
  @campo_obligatorio "Este campo es obligatorio"
  @usuario_mayor_18 "El usuario debe ser mayor de 18 años"
  @monto_invalido -1
  @monto_negativo "Debe ser mayor a cero"


  describe "obtener_usuario/1" do
    test "devuelve el usuario cuando existe" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      assert Entidades.obtener_usuario(usuario.id).id == usuario.id
    end
    test "devuelve nil cuando el usuario no existe" do
      assert Entidades.obtener_usuario(-1) == nil
    end
  end

  describe "obtener_monedas/0" do
    test "retorna todas las monedas existentes" do
      {:ok, moneda_1} = Entidades.crear_moneda(@moneda_default)
      {:ok, moneda_2} = Entidades.crear_moneda(@moneda_alternativa)
      ids =
        Entidades.obtener_monedas()
        |> Enum.map(& &1.id)
        |> Enum.sort()
      assert ids == Enum.sort([moneda_1.id, moneda_2.id])
    end
    test "retorna lista vacía cuando no hay monedas" do
      assert Entidades.obtener_monedas() == []
    end
  end

  describe "obtener_moneda/1" do
    test "devuelve la moneda existente" do
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      assert Entidades.obtener_moneda(moneda.id).id == moneda.id
    end
    test "devuelve nil cuando la moneda no existe" do
      assert Entidades.obtener_moneda(-1) == nil
    end
  end

  describe "obtener_transaccion/1" do
    test "devuelve la transacción existente" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      {:ok, transaccion} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda.id,
          cuenta_origen: usuario.id
        })
      assert Entidades.obtener_transaccion(transaccion.id).id == transaccion.id
    end
    test "devuelve nil cuando la transacción no existe" do
      assert Entidades.obtener_transaccion(-1) == nil
    end
  end
  describe "obtener_transacciones/1" do
    test "filtra transacciones por campo" do
      {:ok, usuario_1} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, usuario_2} =
        Entidades.crear_usuario(%{
          nombre: @nombre_alternativo,
          fecha_nacimiento: @fecha_nacimiento_alternativa
        })
      {:ok, moneda_1} = Entidades.crear_moneda(@moneda_default)
      {:ok, moneda_2} = Entidades.crear_moneda(@moneda_alternativa)
      {:ok, transaccion_1} =
        Entidades.crear_transaccion(%{
          monto: @monto_default,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda_1.id,
          cuenta_origen: usuario_1.id
        })
      {:ok, transaccion_2} =
        Entidades.crear_transaccion(%{
          monto: @monto_alternativo,
          tipo: @tipo_alternativo,
          moneda_origen_id: moneda_2.id,
          cuenta_origen: usuario_2.id
        })
      ids_para_cuenta =
        Entidades.obtener_transacciones(%{cuenta_origen_id: transaccion_1.cuenta_origen_id})
        |> Enum.map(& &1.id)
      assert ids_para_cuenta == [transaccion_1.id]
      assert Enum.empty?(Entidades.obtener_transacciones(%{tipo: @tipo_default}))
      assert Enum.sort([transaccion_1.id, transaccion_2.id]) ==
               Entidades.obtener_transacciones(%{})
               |> Enum.map(& &1.id)
               |> Enum.sort()
    end
  end

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
    test "devuelve error cuando el usuario no existe" do
      assert {:error, :not_found} =
               Entidades.editar_usuario(-1, %{
                 nombre: @nombre_alternativo,
                 fecha_nacimiento: @fecha_nacimiento_alternativa
               })
    end
  end
  describe "crear_cuenta/1" do
    test "crea cuenta válida" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      assert {:ok, cuenta} =
               Entidades.crear_cuenta(%{
                 usuario_id: usuario.id,
                 moneda_id: moneda.id,
                 balance: 500.0
               })
      assert cuenta.balance == 500.0
      assert cuenta.usuario_id == usuario.id
      assert cuenta.moneda_id == moneda.id
    end
    test "retorna errores cuando faltan atributos" do
      assert {:error, changeset} = Entidades.crear_cuenta(%{})
      refute changeset.valid?
      errores = FuncionesDB.errores_en(changeset)
      assert %{
               usuario_id: [@campo_obligatorio],
               moneda_id: [@campo_obligatorio]
             } = Map.take(errores, [:usuario_id, :moneda_id])
    end
  end
  describe "obtener_cuenta/1" do
    test "devuelve la cuenta que coincide con los filtros" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      {:ok, cuenta} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario.id,
          moneda_id: moneda.id,
          balance: 100.0
        })
      assert {:ok, cuenta_encontrada} =
               Entidades.obtener_cuenta(%{usuario_id: usuario.id, moneda_id: moneda.id})
      assert cuenta_encontrada.id == cuenta.id
    end
    test "retorna error cuando la cuenta no existe" do
      assert {:error, :not_found} =
               Entidades.obtener_cuenta(%{usuario_id: -1, moneda_id: -1})
    end
  end
  describe "obtener_cuentas/1" do
    test "filtra cuentas por atributos" do
      {:ok, usuario_principal} =
        Entidades.crear_usuario(%{
          nombre: @nombre_default,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, otro_usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_tercero,
          fecha_nacimiento: @fecha_nacimiento_alternativa
        })
      {:ok, moneda_1} = Entidades.crear_moneda(@moneda_default)
      {:ok, moneda_2} = Entidades.crear_moneda(@moneda_alternativa)
      {:ok, cuenta_1} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario_principal.id,
          moneda_id: moneda_1.id,
          balance: 10.0
        })
      {:ok, cuenta_2} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario_principal.id,
          moneda_id: moneda_2.id,
          balance: 20.0
        })
      {:ok, _cuenta_otro_usuario} =
        Entidades.crear_cuenta(%{
          usuario_id: otro_usuario.id,
          moneda_id: moneda_2.id,
          balance: 30.0
        })
      assert Enum.sort([cuenta_1.id, cuenta_2.id]) ==
               Entidades.obtener_cuentas(%{usuario_id: usuario_principal.id})
               |> Enum.map(& &1.id)
               |> Enum.sort()
      ids_para_moneda =
        Entidades.obtener_cuentas(%{moneda_id: moneda_2.id, usuario_id: usuario_principal.id})
        |> Enum.map(& &1.id)
      assert ids_para_moneda == [cuenta_2.id]
    end
  end
  describe "eliminar_cuenta/1" do
    test "elimina cuenta existente" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_alternativo,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      {:ok, cuenta} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario.id,
          moneda_id: moneda.id,
          balance: 45.0
        })
      assert {:ok, cuenta_eliminada} = Entidades.eliminar_cuenta(cuenta.id)
      assert cuenta_eliminada.id == cuenta.id
      assert Repo.get(Cuenta, cuenta.id) == nil
    end
    test "retorna error cuando la cuenta no existe" do
      assert {:error, :not_found} = Entidades.eliminar_cuenta(-1)
    end
  end
  describe "modificar_cuenta_balance/2" do
    test "ajusta el balance sumando el delta" do
      {:ok, usuario} =
        Entidades.crear_usuario(%{
          nombre: @nombre_tercero,
          fecha_nacimiento: @fecha_nacimiento_default
        })
      {:ok, moneda} = Entidades.crear_moneda(@moneda_tercera)
      {:ok, cuenta} =
        Entidades.crear_cuenta(%{
          usuario_id: usuario.id,
          moneda_id: moneda.id,
          balance: 100.0
        })
      assert {:ok, %Cuenta{} = cuenta_actualizada} =
               Entidades.modificar_cuenta_balance(cuenta.id, 10.5)
      assert_in_delta(cuenta_actualizada.balance, 110.5, 1.0e-6)
    end
    test "retorna error cuando la cuenta no existe" do
      assert {:error, :not_found} = Entidades.modificar_cuenta_balance(-1, 5.0)
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
    test "actualiza precio buscando por id" do
      {:ok, moneda} = Entidades.crear_moneda(@moneda_default)
      assert {:ok, moneda_editada} = Entidades.editar_moneda(moneda.id, 1750.0)
      assert moneda_editada.id == moneda.id
      assert moneda_editada.precio_en_dolares == 1750.0
    end
    test "devuelve error cuando la moneda no existe" do
      assert {:error, :not_found} = Entidades.editar_moneda(-1, 500.0)
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
      {:ok, _segunda_transaccion} = Entidades.crear_transaccion(atributos)

      assert {:error, changeset} = Entidades.deshacer_transaccion(primera_transaccion.id)

      assert %{
               base: ["solo se puede deshacer la última transacción de cada cuenta involucrada"]
             } = FuncionesDB.errores_en(changeset)
    end
  end
end
