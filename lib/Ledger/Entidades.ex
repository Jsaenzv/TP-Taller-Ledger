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

  def crear_transaccion(
        monto,
        tipo,
        id_moneda_origen,
        id_moneda_destino,
        id_cuenta_origen,
        id_cuenta_destino
      ) do
    atributos = %{
      monto: monto,
      tipo: tipo,
      moneda_origen_id: id_moneda_origen,
      moneda_destino_id: id_moneda_destino,
      cuenta_origen_id: id_cuenta_origen,
      cuenta_destino_id: id_cuenta_destino
    }

    Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()
  end
end
