defmodule Ledger.Entidades.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  schema "usuarios" do
    field(:nombre, :string)
    field(:fecha_nacimiento, :date)
    timestamps()
  end

  @edad_minima 18
  def changeset(usuario, atributos) do
    usuario
    |> cast(atributos, [:nombre, :fecha_nacimiento])
    |> validate_required([:nombre, :fecha_nacimiento], message: "Este campo es obligatorio")
    |> validate_change(:fecha_nacimiento, fn :fecha_nacimiento, fecha ->
      dias = Date.diff(Date.utc_today(), fecha)

      if dias >= @edad_minima * 365 do
        []
      else
        [fecha_nacimiento: "El usuario debe ser mayor de #{@edad_minima} años"]
      end
    end)
    |> unique_constraint([:nombre],
      name: :users_nombre_index,
      message: "Ya existe un usuario con ese nombre"
    )
  end
end
