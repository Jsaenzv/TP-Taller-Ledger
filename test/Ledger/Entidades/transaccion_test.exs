defmodule Ledger.Entidades.TransaccionTest do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario}
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

  describe "changeset válido" do
    test "devuelve un changeset válido cuando los atributos están completos", %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: 125.5,
        tipo: "transferencia",
        moneda_origen_id: moneda_origen.id,
        moneda_destino_id: moneda_destino.id,
        cuenta_origen: cuenta_origen.id,
        cuenta_destino: cuenta_destino.id
      }

      changeset = Transaccion.changeset(%Transaccion{}, atributos)

      assert changeset.valid?

      assert %{monto: 125.5, tipo: "transferencia"} = changeset.changes
      assert changeset.changes.moneda_origen_id == moneda_origen.id
      assert changeset.changes.moneda_destino_id == moneda_destino.id
      assert changeset.changes.cuenta_origen == cuenta_origen.id
      assert changeset.changes.cuenta_destino == cuenta_destino.id

      assert %{} == errores_en(changeset)
    end

    test "devuelve un error porque falta monto" , %{
      moneda_origen: moneda_origen,
      moneda_destino: moneda_destino,
      cuenta_origen: cuenta_origen,
      cuenta_destino: cuenta_destino
    } do
      atributos = %{
        monto: nil,
        tipo: "transferencia",
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

      assert %{monto: ["Este campo es obligatorio"]} == errores_en(changeset)
    end
    # test: Validaciones mínimas: faltan :monto, :tipo, :moneda_origen_id o :cuenta_origen → el changeset debe ser inválido y contener los errores esperados.
    # test: Monto negativo o cero → validate_number debería marcar error.
    # test: Referencia a moneda/cuenta inexistente → tras intentar Repo.insert, deberías obtener un error de constraint (requiere fixtures/mocks para monedas y usuarios creados de antemano o uso de sandbox).
  end

  describe "reversal_changeset/2" do
    # test: Caso feliz: crear una transacción, luego pasarla a reversal_changeset y verificar que el changeset resultante sea válido y que los campos estén correctamente invertidos.
    # test: No es la última transacción: insertar dos transacciones para la misma cuenta en orden cronológico y llamar a reversal_changeset con la primera; debería devolver error en :base.
    # test: Transacción sin cuenta destino: crear una transacción con cuenta_destino nil y confirmar que la reversión mantiene esa ausencia coherentemente.
  end

  defp errores_en(changeset) do
    traverse_errors(changeset, fn {mensaje, opciones} ->
      Enum.reduce(opciones, mensaje, fn {clave, valor}, acumulado ->
        String.replace(acumulado, "%{#{clave}}", to_string(valor))
      end)
    end)
  end
end
