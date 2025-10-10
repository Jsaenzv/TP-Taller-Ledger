defmodule Ledger.Entidades do

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Repo

  def crear_usuario(nombre, fecha_nacimiento) do
    atributos = %{nombre: nombre, fecha_nacimiento: fecha_nacimiento}
    case Usuario.changeset(%Usuario{}, atributos) |> Repo.insert() do
      {:ok, _changeset} -> "El usuario ha sido creado con éxito"
      {:error, changeset} ->
        error = FuncionesDB.errores_en(changeset)
        "Error al crear usuario: #{error}"
    end


  end
end
