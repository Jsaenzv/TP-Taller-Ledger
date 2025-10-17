defmodule Ledger.Entidades do
  alias Ledger.Entidades.{Cuenta, Moneda, Transaccion, Usuario}
  alias Ledger.Repo

  def obtener_usuario(id_usuario) do
    Repo.get(Usuario, id_usuario)
  end

  def obtener_transaccion(id_transaccion) do
    Repo.get(Transaccion, id_transaccion)
  end

  def obtener_moneda(id_moneda) do
    Repo.get(Moneda, id_moneda)
  end

  def crear_usuario(atributos) when is_map(atributos) do
    Usuario.changeset(%Usuario{}, atributos) |> Repo.insert()
  end

  def editar_usuario(id_usuario, atributos) do
    usuario = Repo.get(Usuario, id_usuario)

    case usuario do
      nil -> {:error, :not_found}
      _ -> Usuario.changeset(usuario, atributos) |> Repo.update()
    end
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

  def crear_cuenta(atributos) when is_map(atributos) do
    Cuenta.changeset(%Cuenta{}, atributos) |> Repo.insert()
  end

  def editar_moneda(%Moneda{} = moneda, precio_en_dolares) do
    Moneda.changeset(moneda, %{precio_en_dolares: precio_en_dolares}) |> Repo.update()
  end

  def editar_moneda(id_moneda, precio_en_dolares) do
    case Repo.get(Moneda, id_moneda) do
      nil ->
        {:error, :not_found}

      %Moneda{} = moneda ->
        editar_moneda(moneda, precio_en_dolares)
    end
  end

  def eliminar_moneda(id_moneda) do
    moneda = Repo.get(Moneda, id_moneda)

    case moneda do
      nil -> {:error, :not_found}
      _ -> Repo.delete(moneda)
    end
  end

  def eliminar_cuenta(id_cuenta) do
    cuenta = Repo.get(Cuenta, id_cuenta)

    case cuenta do
      nil -> {:error, :not_found}
      _ -> Repo.delete(cuenta)
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
