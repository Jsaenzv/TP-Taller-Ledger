defmodule Ledger.Entidades do
  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Repo

  def crear_usuario(atributos) when is_map(atributos) do
    Usuario.changeset(%Usuario{}, atributos) |> Repo.insert()
  end

  def editar_usuario(usuario, atributos) do
    Usuario.changeset(usuario, atributos) |> Repo.update()
  end

  def eliminar_usuario(id_usuario) do
    usuario = Repo.get(Usuario, id_usuario)
    case usuario do
      nil -> {:error, :not_found}
      _ -> Repo.delete(usuario)
    end
  end

  def crear_transaccion(atributos) when is_map(atributos) do
    Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()
  end

  def crear_moneda(atributos) when is_map(atributos) do
    Moneda.changeset(%Moneda{}, atributos) |> Repo.insert()
  end

  def editar_moneda(%Moneda{} = moneda, precio_en_dolares) do
    Moneda.changeset(moneda, %{precio_en_dolares: precio_en_dolares}) |> Repo.update()
  end

  def eliminar_moneda(id_moneda) do
    moneda = Repo.get(Moneda, id_moneda)
    case moneda do
      nil -> {:error, :not_found}
      _ -> Repo.delete(moneda)
    end
  end

  def deshacer_transaccion(id_transaccion) do
    case Repo.get(Transaccion, id_transaccion) do
      nil ->
        {:error, :not_found}

      transaccion ->
        transaccion
        |> Transaccion.reversal_changeset()
        |> Repo.insert()
    end
  end
end
