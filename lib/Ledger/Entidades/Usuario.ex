defmodule Ledger.Entidades.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  schema "usuarios" do
    field(:nombre, :string)
    field(:fecha_nacimiento, :date)
    timestamps()
  end

  def changeset(usuario, atributos) do
    usuario
    |> cast(atributos, [:nombre, :fecha_nacimiento])
    |> validate_required([:nombre, :fecha_nacimiento])
    |> unique_constraint([:nombre])
  end
end
