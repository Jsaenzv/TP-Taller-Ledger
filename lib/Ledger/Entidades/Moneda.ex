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
    |> validate_required([:nombre, :precio_en_dolares], message: "Este campo es obligatorio")
    |> unique_constraint([:nombre], message: "Ya existe una moneda con ese nombre")
    |> validate_length(:nombre, min: 3, max: 4, message: "El nombre debe tener 3 o 4 caracteres")
    |> validate_format(:nombre, ~r/^[A-Z]+$/, message: "Formato inválido")
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
