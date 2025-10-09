defmodule Ledger.Entidades.Transaccion do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ledger.Repo
  alias Ledger.Entidades.{Moneda, Usuario}

  schema "transacciones" do
    field(:monto, :float)
    field(:tipo, :string)
    belongs_to(:moneda_origen, Moneda)
    belongs_to(:moneda_destino, Moneda)
    field(:cuenta_origen, :id)
    field(:cuenta_destino, :id)

    belongs_to(:cuenta_origen_usuario, Usuario,
      foreign_key: :cuenta_origen,
      references: :id,
      define_field: false
    )

    belongs_to(:cuenta_destino_usuario, Usuario,
      foreign_key: :cuenta_destino,
      references: :id,
      define_field: false
    )

    field(:deshacer_de_id, :id, virtual: true)
    timestamps()
  end

  def changeset(transaccion, atributos) do
    transaccion
    |> cast(atributos, [
      :monto,
      :tipo,
      :moneda_origen_id,
      :moneda_destino_id,
      :cuenta_origen,
      :cuenta_destino
    ])
    |> validate_required([:monto, :tipo, :moneda_origen_id, :cuenta_origen],
         message: "Este campo es obligatorio"
       )
    |> validar_destinos_si_transferencia()
    |> validate_number(:monto, greater_than: 0, message: "Debe ser mayor a cero")
    |> assoc_constraint(:moneda_origen, message: "Debe existir en la tabla Monedas")
    |> assoc_constraint(:moneda_destino, message: "Debe existir en la tabla Monedas")
    |> assoc_constraint(:cuenta_origen_usuario, message: "Debe existir en la tabla Usuarios")
    |> assoc_constraint(:cuenta_destino_usuario, message: "Debe existir en la tabla Usuarios")
end

defp validar_destinos_si_transferencia(changeset) do
  case get_field(changeset, :tipo) do
    "transferencia" ->
      validate_required(changeset, [:moneda_destino_id, :cuenta_destino],
        message: "Este campo es obligatorio en caso de transferencia"
      )

    _ ->
      changeset
  end
end


  def reversal_changeset(%__MODULE__{} = original, repo \\ Repo) do
    original
    |> crear_atributos_opuestos()
    |> Map.put(:deshacer_de_id, original.id)
    |> then(fn atributos_finales ->
      %__MODULE__{}
      |> cast(atributos_finales, [
        :monto,
        :tipo,
        :moneda_origen_id,
        :moneda_destino_id,
        :cuenta_origen,
        :cuenta_destino,
        :deshacer_de_id
      ])
      |> validate_required([:monto, :tipo, :moneda_origen_id, :cuenta_origen, :deshacer_de_id], message: "Este campo es obligatorio")
      |> validate_change(:deshacer_de_id, fn :deshacer_de_id, value ->
        if value == original.id do
          []
        else
          [deshacer_de_id: "no coincide con la transacción original"]
        end
      end)
      |> validate_number(:monto, greater_than: 0, message: "Debe ser mayor a cero")
      |> assoc_constraint(:moneda_origen, message: "Debe existir en la tabla Monedas")
      |> assoc_constraint(:moneda_destino, message: "Debe existir en la tabla Monedas")
      |> assoc_constraint(:cuenta_origen_usuario, message: "Debe existir en la tabla Usuarios")
      |> assoc_constraint(:cuenta_destino_usuario, message: "Debe existir en la tabla Usuarios")
      |> verificar_ultima_transaccion(original, repo)
    end)
  end

  defp crear_atributos_opuestos(original) do
    %{
      monto: original.monto,
      tipo: "reversa",
      moneda_origen_id: original.moneda_destino_id || original.moneda_origen_id,
      moneda_destino_id: original.moneda_origen_id,
      cuenta_origen: original.cuenta_destino || original.cuenta_origen,
      cuenta_destino: original.cuenta_destino && original.cuenta_origen
    }
  end

  defp verificar_ultima_transaccion(%Ecto.Changeset{valid?: false} = changeset, _original, _repo),
    do: changeset

  defp verificar_ultima_transaccion(changeset, original, repo) do
    cuentas =
      [original.cuenta_origen, original.cuenta_destino]
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    ultima_transaccion_para_todas? =
      Enum.all?(cuentas, fn id_cuenta ->
        ultima_transaccion(id_cuenta, repo)
        |> case do
          nil -> false
          %{id: id} -> id == original.id
        end
      end)

    if ultima_transaccion_para_todas? do
      changeset
    else
      add_error(
        changeset,
        :base,
        "solo se puede deshacer la última transacción de cada cuenta involucrada"
      )
    end
  end

  defp ultima_transaccion(id_cuenta, repo) do
    __MODULE__
    |> where([t], t.cuenta_origen == ^id_cuenta or t.cuenta_destino == ^id_cuenta)
    |> order_by([t], desc: t.inserted_at, desc: t.id)
    |> limit(1)
    |> repo.one()
  end
end
