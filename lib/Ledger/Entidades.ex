defmodule Ledger.Entidades do

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Repo

  def crear_usuario(nombre, fecha_nacimiento) do
    atributos = %{nombre: nombre, fecha_nacimiento: fecha_nacimiento}
    Usuario.changeset(%Usuario{}, atributos) |> Repo.insert()
  end

  def editar_usuario(usuario, atributos) do
      Usuario.changeset(usuario, atributos) |> Repo.update()
  end

  def eliminar_usuario(usuario) do
    Repo.delete(usuario)
  end
end
