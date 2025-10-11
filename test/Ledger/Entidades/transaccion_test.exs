defmodule Ledger.Entidades.TransaccionTest do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})

    moneda_origen =
      %Moneda{}
      |> Moneda.changeset(%{nombre: "USD", precio_en_dolares: 1.0})
      |> Repo.insert!()

    moneda_destino =
      %Moneda{}
      |> Moneda.changeset(%{nombre: "ARS", precio_en_dolares: 0.001})
      |> Repo.insert!()

    cuenta_origen =
      %Usuario{}
      |> Usuario.changeset(%{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]})
      |> Repo.insert!()

    cuenta_destino =
      %Usuario{}
      |> Usuario.changeset(%{nombre: "pedro", fecha_nacimiento: ~D[1992-02-02]})
      |> Repo.insert!()

    {:ok,
     moneda_origen: moneda_origen,
     moneda_destino: moneda_destino,
     cuenta_origen: cuenta_origen,
     cuenta_destino: cuenta_destino}
  end

  describe "changeset/2" do
    @monto_default 100.5
    @tipo_default "transferencia"
    test "devuelve un changeset válido cuando los atributos están completos", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: @monto_default,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      assert changeset.valid?

      assert %{monto: @monto_default, tipo: @tipo_default} = changeset.changes
      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{} == FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta monto", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: nil,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      alias Ledger.Entidades.FuncionesDB
      assert %{monto: ["Este campo es obligatorio"]} == FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta tipo", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 110.5,
        tipo: nil,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{tipo: ["Este campo es obligatorio"]} == FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta moneda_origen_id", %{
      moneda_origen: _moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 110.5,
        tipo: @tipo_default,
        moneda_origen_id: nil,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{moneda_origen_id: ["Este campo es obligatorio"]} ==
               FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta cuenta_origen", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: _cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 110.5,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: nil,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{cuenta_origen: ["Este campo es obligatorio"]} == FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta moneda_destino y el tipo es transferencia", %{
      moneda_origen: moneda_origen,
      moneda_destino: _moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 110.5,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: nil,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{moneda_destino_id: ["Este campo es obligatorio en caso de transferencia"]} ==
               FuncionesDB.errores_en(changeset)
    end

    test "devuelve un error porque falta cuenta_destino y el tipo es transferencia", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: _cuenta_destino
    } do
      atributos = %{
        monto: 110.5,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: nil
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id

      assert %{cuenta_destino: ["Este campo es obligatorio en caso de transferencia"]} ==
               FuncionesDB.errores_en(changeset)
    end

    @monto_negativo -1
    test "devuelve un error porque el monto es negativo", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: @monto_negativo,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      refute changeset.valid?

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{monto: ["Debe ser mayor a cero"]} == FuncionesDB.errores_en(changeset)
    end

    @moneda_origen_id_inexistente 1_000_000
    test "devuelve error porque la moneda_origen no existe en la tabla Monedas", %{
      moneda_origen: _moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 100,
        tipo: @tipo_default,
        moneda_origen_id: @moneda_origen_id_inexistente,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      {:error, changeset} = Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()

      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{moneda_origen: ["Debe existir en la tabla Monedas"]} ==
               FuncionesDB.errores_en(changeset)
    end

    @moneda_destino_id_inexistente 1_000_000
    test "devuelve error porque la moneda_destino no existe en la tabla Monedas", %{
      moneda_origen: moneda_origen,
      moneda_destino: _moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 100,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: @moneda_destino_id_inexistente,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      {:error, changeset} = Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{moneda_destino: ["Debe existir en la tabla Monedas"]} ==
               FuncionesDB.errores_en(changeset)
    end

    @cuenta_origen_inexistente 1_000_000
    test "devuelve error porque la cuenta origen no existe en la tabla Usuarios", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: _cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 100,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: @cuenta_origen_inexistente,
        cuenta_destino: cuenta_destino.id
      }

      {:error, changeset} = Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{cuenta_origen_usuario: ["Debe existir en la tabla Usuarios"]} ==
               FuncionesDB.errores_en(changeset)
    end

    @cuenta_destino_inexistente 1_000_000
    test "devuelve error porque la cuenta destino no existe en la tabla Usuarios", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: _cuenta_destino
    } do
      atributos = %{
        monto: 100,
        tipo: @tipo_default,
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: @cuenta_destino_inexistente
      }

      {:error, changeset} = Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()

      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id

      assert %{cuenta_destino_usuario: ["Debe existir en la tabla Usuarios"]} ==
               FuncionesDB.errores_en(changeset)
    end
  end

  describe "reversal_changeset/2" do
    test "devuelve un changeset válido con los campos invertidos", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      transaccion =
        %Transaccion{}
        |> Transaccion.changeset(%{
          monto: @monto_default,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: cuenta_origen.id,
          cuenta_destino: cuenta_destino.id
        })
        |> Repo.insert!()

      changeset = Transaccion.reversal_changeset(transaccion)

      assert changeset.valid?
      assert changeset.changes.tipo == "reversa"
      assert changeset.changes.monto == transaccion.monto
      assert changeset.changes.moneda_origen_id == transaccion.moneda_destino_id
      assert changeset.changes.moneda_destino_id == transaccion.moneda_origen_id
      assert changeset.changes.cuenta_origen == transaccion.cuenta_destino
      assert changeset.changes.cuenta_destino == transaccion.cuenta_origen
      assert changeset.changes.deshacer_de_id == transaccion.id
    end

    test "Error al intentar revertir una transacción que no es la ultima", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      transaccion_1 =
        %Transaccion{}
        |> Transaccion.changeset(%{
          monto: @monto_default,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: cuenta_origen.id,
          cuenta_destino: cuenta_destino.id
        })
        |> Repo.insert!()

      _transaccion_2 =
        %Transaccion{}
        |> Transaccion.changeset(%{
          monto: @monto_default,
          tipo: @tipo_default,
          moneda_origen_id: moneda_origen.id,
          moneda_destino_id: moneda_destino.id,
          cuenta_origen: cuenta_origen.id,
          cuenta_destino: cuenta_destino.id
        })
        |> Repo.insert!()

      changeset = Transaccion.reversal_changeset(transaccion_1)

      refute changeset.valid?

      assert %{base: ["solo se puede deshacer la última transacción de cada cuenta involucrada"]} ==
               FuncionesDB.errores_en(changeset)
    end

    # test: Transacción sin cuenta destino: crear una transacción con cuenta_destino nil y confirmar que la reversión mantiene esa ausencia coherentemente.
  end
end
