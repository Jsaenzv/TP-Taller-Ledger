defmodule Ledger.Entidades.Cuenta do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Entidades.{Moneda, Usuario}

  schema "cuentas" do
    belongs_to(:usuario, Usuario)
    belongs_to(:moneda, Moneda)
    field(:balance, :float, default: 0.0)
    timestamps()
  end

  def changeset(cuenta, attrs) do
    cuenta
    |> cast(attrs, [:usuario_id, :moneda_id, :balance])
    |> validate_required([:usuario_id, :moneda_id, :balance],
      message: "Este campo es obligatorio"
    )
    |> unique_constraint([:usuario_id, :moneda_id], name: :cuentas_usuario_id_moneda_id)
  end
end
