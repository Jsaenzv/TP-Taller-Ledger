defmodule Ledger.Entidades.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:nombre, :string)
    field(:fecha_nacimiento, :date)
    timestamps()
  end

  def changeset(user, atributos) do
    user
    |> cast(atributos, [:nombre, :fecha_nacimiento])
    |> validate_required([:nombre, :fecha_nacimiento])
    |> unique_constraint([:nombre])
  end
end
