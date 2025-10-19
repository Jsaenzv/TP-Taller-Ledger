defmodule Ledger.Entidades do
  alias Ecto.Changeset
  alias Ledger.Entidades.{Cuenta, Moneda, Transaccion, Usuario}
  alias Ledger.Repo
  import Ecto.Query

  def obtener_usuario(id_usuario) do
    Repo.get(Usuario, id_usuario)
  end

  def obtener_monedas() do
    Repo.all(Moneda)
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

    Repo.delete_all(from(c in Cuenta, where: c.usuario_id == ^id_usuario))

    case usuario do
      nil -> {:error, :not_found}
      _ -> Repo.delete(usuario)
    end
  end

  def crear_transaccion(atributos) when is_map(atributos) do
    tipo = Map.get(atributos, :tipo)

    Repo.transaction(fn ->
      resultado =
        case tipo do
          "alta_cuenta" -> crear_transaccion_alta(atributos)
          "transferencia" -> crear_transaccion_transferencia(atributos)
          "swap" -> crear_transaccion_swap(atributos)
          _ -> insertar_transaccion(atributos)
        end

      case resultado do
        {:ok, transaccion} -> transaccion
        {:error, %Changeset{} = changeset} -> Repo.rollback(changeset)
        {:error, razon} -> Repo.rollback(razon)
      end
    end)
    |> case do
      {:ok, transaccion} -> {:ok, transaccion}
      {:error, %Changeset{} = changeset} -> {:error, changeset}
      {:error, razon} -> {:error, razon}
    end
  end

  def crear_moneda(atributos) when is_map(atributos) do
    Moneda.changeset(%Moneda{}, atributos) |> Repo.insert()
  end

  def crear_cuenta(atributos) when is_map(atributos) do
    Cuenta.changeset(%Cuenta{}, atributos) |> Repo.insert()
  end

  def obtener_transacciones(filtros) when is_map(filtros) do
    query =
      Enum.reduce(filtros, from(t in Transaccion), fn {campo, valor}, acc ->
        from(t in acc, where: field(t, ^campo) == ^valor)
      end)

    Repo.all(query)
  end

  def obtener_cuenta(filtros) when is_map(filtros) do
    query =
      Enum.reduce(filtros, from(c in Cuenta), fn {campo, valor}, acc ->
        from(c in acc, where: field(c, ^campo) == ^valor)
      end)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      cuenta -> {:ok, cuenta}
    end
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

  def modificar_cuenta_balance(id_cuenta, delta_balance) do
    case Repo.get(Cuenta, id_cuenta) do
      nil ->
        {:error, :not_found}

      %Cuenta{} = cuenta ->
        nuevo_balance = (cuenta.balance || 0.0) + delta_balance

        cuenta
        |> Changeset.change(%{balance: nuevo_balance})
        |> Repo.update()
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

  defp crear_transaccion_alta(atributos) do
    usuario_id = Map.get(atributos, :cuenta_origen)
    moneda_id = Map.get(atributos, :moneda_origen_id)
    monto = Map.get(atributos, :monto)

    cuenta =
      case crear_cuenta(%{usuario_id: usuario_id, moneda_id: moneda_id, balance: monto}) do
        {:ok, cuenta} -> cuenta
        {:error, %Changeset{} = changeset} -> Repo.rollback(changeset)
        {:error, razon} -> Repo.rollback(razon)
      end

    atributos
    |> Map.put(:cuenta_origen_id, cuenta.id)
    |> Map.put(:moneda_origen_id, moneda_id)
    |> insertar_transaccion()
  end

  def obtener_cuentas(filtros) do
    query =
      Enum.reduce(filtros, from(c in Cuenta), fn {campo, valor}, acc ->
        from(t in acc, where: field(t, ^campo) == ^valor)
      end)

    Repo.all(query)
  end

  defp crear_transaccion_transferencia(atributos) do
    usuario_origen = Map.get(atributos, :cuenta_origen)
    usuario_destino = Map.get(atributos, :cuenta_destino)
    moneda_origen_id = Map.get(atributos, :moneda_origen_id)
    moneda_destino_id = Map.get(atributos, :moneda_destino_id)
    {monto, _} = Float.parse(Map.get(atributos, :monto))

    cuenta_origen =
      case obtener_cuenta(usuario_origen, moneda_origen_id) do
        {:ok, cuenta_origen} -> cuenta_origen
        {:error, razon} -> Repo.rollback(razon)
      end

    cuenta_destino =
      case obtener_cuenta(usuario_destino, moneda_destino_id) do
        {:ok, cuenta_destino} -> cuenta_destino
        {:error, razon} -> Repo.rollback(razon)
      end

    balance = obtener_balance(cuenta_origen.id)

    case balance - monto do
      n when n >= 0 ->
        modificar_cuenta_balance(cuenta_origen.id, -monto)
        modificar_cuenta_balance(cuenta_destino.id, monto)

      _ ->
        Repo.rollback("saldo insuficiente")
    end

    atributos
    |> Map.put(:cuenta_origen_id, cuenta_origen.id)
    |> Map.put(:cuenta_destino_id, cuenta_destino.id)
    |> Map.put(:moneda_origen_id, moneda_origen_id)
    |> Map.put(:moneda_destino_id, moneda_destino_id)
    |> insertar_transaccion()
  end

  defp obtener_balance(id_cuenta) do
    case Repo.get(Cuenta, id_cuenta) do
      nil -> {:error, :not_found}
      %Cuenta{} = cuenta -> cuenta.balance
    end
  end

  defp crear_transaccion_swap(atributos) do
    usuario_id = Map.get(atributos, :cuenta_origen)
    moneda_origen_id = Map.get(atributos, :moneda_origen_id)
    moneda_destino_id = Map.get(atributos, :moneda_destino_id)
    {monto, _} = Float.parse(Map.get(atributos, :monto))

    cuenta_origen =
      case obtener_cuenta(usuario_id, moneda_origen_id) do
        {:ok, cuenta_origen} -> cuenta_origen
        {:error, razon} -> Repo.rollback(razon)
      end

    cuenta_destino =
      case obtener_cuenta(usuario_id, moneda_destino_id) do
        {:ok, cuenta_destino} -> cuenta_destino
        {:error, razon} -> Repo.rollback(razon)
      end

    modificar_cuenta_balance(cuenta_origen.id, -monto)
    modificar_cuenta_balance(cuenta_destino.id, monto)

    atributos
    |> Map.put(:cuenta_origen_id, cuenta_origen.id)
    |> Map.put(:cuenta_destino_id, cuenta_destino.id)
    |> Map.put(:moneda_origen_id, moneda_origen_id)
    |> Map.put(:moneda_destino_id, moneda_destino_id)
    |> insertar_transaccion()
  end

  defp insertar_transaccion(atributos) do
    Transaccion.changeset(%Transaccion{}, atributos) |> Repo.insert()
  end

  defp obtener_cuenta(usuario_id, moneda_id) do
    case obtener_cuenta(%{usuario_id: usuario_id, moneda_id: moneda_id}) do
      {:ok, cuenta} ->
        {:ok, cuenta}

      {:error, :not_found} ->
        {:error,
         "El usuario con id: #{usuario_id} no tiene una cuenta con la moneda con id: #{moneda_id}"}
    end
  end
end
