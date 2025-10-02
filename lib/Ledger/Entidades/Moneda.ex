defmodule Ledger.Entidades.Moneda do
  use Ecto.Schema
  import Ecto.Changeset

  schema "monedas" do
    field(:nombre, :string)
    field(:precio_en_dolares, :float)
    timestamps()
  end

  def changeset(moneda, atributos) do
    moneda
    |> cast(atributos, [:nombre, :precio_en_dolares])
    |> validate_required([:nombre, :precio_en_dolares])
    |> unique_constraint([:nombre])
    |> validate_length(:nombre, min: 3, max: 4)
    |> validate_format(:nombre, ~r/^[A-Z]+$/)
    |> prohibir_modificacion_nombre()
  end

  defp prohibir_modificacion_nombre(%Ecto.Changeset{data: %{id: nil}} = changeset), do: changeset

  defp prohibir_modificacion_nombre(changeset) do
    case get_change(changeset, :nombre) do
      nil -> changeset
      _ -> add_error(changeset, :nombre, "no se puede modificar una vez creado")
    end
  end
end
