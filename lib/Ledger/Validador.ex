defmodule Ledger.Validador do
  alias Ledger.Parser
  alias Ledger.Constantes

  def validar_flags(flags, :crear_usuario) do
    obligatorios = ["nombre_usuario", "fecha_nacimiento"]

    cond do
      Enum.sort(Map.keys(flags)) != Enum.sort(obligatorios) ->
        {:error,
         "flags permitidos: #{Enum.join(obligatorios, ", ")}. flags obtenidos: #{Enum.join(Map.keys(flags), ", ")}"}

      Enum.any?(obligatorios, &(flags[&1] in [nil, ""])) ->
        {:error, "nombre_usuario y fecha_nacimiento son obligatorios"}

      true ->
        :ok
    end
  end

  def validar_flags(flags, :eliminar_usuario) do
    obligatorios = ["id_usuario"]

    cond do
      Enum.sort(Map.keys(flags)) != Enum.sort(obligatorios) ->
        {:error,
         "flags permitidos: #{Enum.join(obligatorios, ", ")}. flags obtenidos: #{Enum.join(Map.keys(flags), ", ")}"}

      Enum.any?(obligatorios, &(flags[&1] in [nil, ""])) ->
        {:error, "id_usuario es obligatorio"}

      true ->
        :ok
    end
  end

  def validar_flags(flags, :editar_usuario) do
    obligatorios = ["id_usuario"]
    permitidos = ["id_usuario", "nombre_usuario", "fecha_nacimiento"]

    keys = Map.keys(flags)

    cond do
      Enum.any?(obligatorios, &(flags[&1] in [nil, ""])) ->
        {:error, "Los campos obligatorios no pueden ser vacíos: #{Enum.join(obligatorios, ", ")}"}

      Enum.any?(keys, fn k -> k not in permitidos end) ->
        extras = Enum.filter(keys, fn k -> k not in permitidos end)

        {:error,
         "flags no permitidos: #{Enum.join(extras, ", ")}. Permitidos: #{Enum.join(permitidos, ", ")}"}

      not Enum.all?(obligatorios, &(&1 in keys)) ->
        faltantes = Enum.filter(obligatorios, &(!(&1 in keys)))
        {:error, "Faltan flags obligatorios: #{Enum.join(faltantes, ", ")}"}

      true ->
        :ok
    end
  end

  def validar_flags(flags, comando) do
    case comando do
      :balance ->
        with {:ok, _cuenta_origen} <- campo_obligatorio(flags, "cuenta_origen"),
             :ok <- campo_vacio(flags, "cuenta_destino") do
          :ok
        else
          {:error, razon} -> {:error, razon}
        end

      :transacciones ->
        with :ok <- campo_vacio(flags, "moneda") do
          :ok
        else
          {:error, razon} -> {:error, razon}
        end
    end
  end

  defp campo_vacio(mapa, campo) do
    case Map.get(mapa, campo) do
      nil -> :ok
      _ -> {:error, "Campo #{campo} debe estar vacío."}
    end
  end

  def validar_transacciones(transacciones, tipos_de_cambio) do
    estado_inicial = %{cuentas_alta: MapSet.new(), balances: %{}, tipos: tipos_de_cambio}

    case reducir_validando(transacciones, estado_inicial) do
      {:ok, _estado_final} -> :ok
      {:error, razon} -> {:error, razon}
    end
  end

  def reducir_validando(transacciones, estado_inicial) do
    transacciones
    |> Enum.with_index(1)
    |> Enum.reduce_while(estado_inicial, fn {fila, linea}, estado_actual ->
      case validar_y_aplicar(fila, linea, estado_actual) do
        {:ok, nuevo_estado} -> {:cont, nuevo_estado}
        {:error, razon} -> {:halt, {:error, razon}}
      end
    end)
    |> case do
      {:error, razon} -> {:error, razon}
      estado_final -> {:ok, estado_final}
    end
  end

  def validar_y_aplicar(
        fila,
        linea,
        %{cuentas_alta: cuentas, balances: balances, tipos: tipos} = estado_actual
      ) do
    with {:ok, tipo} <- campo_obligatorio(fila, "tipo"),
         :ok <- validar_tipo(tipo),
         {:ok, monto} <- Parser.parsear_monto(fila["monto"]),
         {:ok, moneda_origen} <- campo_obligatorio(fila, "moneda_origen"),
         :ok <- validar_moneda(moneda_origen, tipos) do
      case tipo do
        "alta_cuenta" ->
          {:ok,
           %{
             estado_actual
             | cuentas_alta: MapSet.put(cuentas, fila["cuenta_origen"]),
               balances: sumar_balance(balances, fila["cuenta_origen"], moneda_origen, monto)
           }}

        "transferencia" ->
          with {:ok, cuenta_origen} <- campo_obligatorio(fila, "cuenta_origen"),
               {:ok, cuenta_destino} <- campo_obligatorio(fila, "cuenta_destino"),
               :ok <- cuenta_dada_de_alta(cuentas, cuenta_origen),
               :ok <- cuenta_dada_de_alta(cuentas, cuenta_destino),
               {:ok, moneda_destino} <- campo_obligatorio(fila, "moneda_destino"),
               :ok <- validar_moneda(moneda_destino, tipos),
               :ok <- saldo_suficiente(balances, cuenta_origen, moneda_origen, monto) do
            monto_destino = convertir(tipos, moneda_origen, moneda_destino, monto)

            balances_nuevos =
              balances
              |> sumar_balance(cuenta_origen, moneda_origen, -monto)
              |> sumar_balance(cuenta_destino, moneda_destino, monto_destino)

            {:ok, %{estado_actual | balances: balances_nuevos}}
          else
            {:error, razon} ->
              {:error, "Error en la línea #{linea} (sin contar encabezados), razon: #{razon}"}
          end

        "swap" ->
          with {:ok, cuenta_origen} <- campo_obligatorio(fila, "cuenta_origen"),
               :ok <- cuenta_dada_de_alta(cuentas, cuenta_origen),
               {:ok, moneda_destino} <- campo_obligatorio(fila, "moneda_destino"),
               :ok <- validar_moneda(moneda_destino, tipos),
               :ok <- saldo_suficiente(balances, cuenta_origen, moneda_origen, monto) do
            monto_destino = convertir(tipos, moneda_origen, moneda_destino, monto)

            balances_nuevos =
              balances
              |> sumar_balance(cuenta_origen, moneda_origen, -monto)
              |> sumar_balance(cuenta_origen, moneda_destino, monto_destino)

            {:ok, %{estado_actual | balances: balances_nuevos}}
          else
            {:error, razon} ->
              {:error, "Error en la línea #{linea} (sin contar encabezados), razon: #{razon}"}
          end
      end
    else
      {:error, razon} ->
        {:error, "Error en la línea #{linea} (sin contar encabezados), razon: #{razon}"}
    end
  end

  def validar_tipo(tipo) do
    case tipo in Constantes.tipos_validos() do
      true -> :ok
      _otro -> {:error, "Tipo inválido '#{tipo}'"}
    end
  end

  def campo_obligatorio(mapa, campo) do
    case mapa[campo] do
      nil -> {:error, "Campo obligatorio faltante: #{campo}"}
      "" -> {:error, "Campo obligatorio vacío: #{campo}"}
      v -> {:ok, v}
    end
  end

  def validar_moneda(moneda, tipos) do
    if Map.has_key?(tipos, moneda) do
      :ok
    else
      {:error, "Moneda no listada en monedas.csv: #{moneda}"}
    end
  end

  def cuenta_dada_de_alta(cuentas, cuenta) do
    if MapSet.member?(cuentas, cuenta) do
      :ok
    else
      {:error, "La cuenta '#{cuenta}' no fue dada de alta previamente"}
    end
  end

  def saldo_suficiente(balances, cuenta, moneda, monto) do
    saldo = obtener_saldo(balances, cuenta, moneda)

    if saldo >= monto do
      :ok
    else
      {:error,
       "Saldo insuficiente en '#{cuenta}' para #{moneda}. requerido=#{monto}, disponible=#{saldo}"}
    end
  end

  def obtener_saldo(balances, cuenta, moneda) do
    balances
    |> Map.get(cuenta, %{})
    |> Map.get(moneda, 0.0)
  end

  def sumar_balance(balances, cuenta, moneda, monto) do
    Map.update(balances, cuenta, %{moneda => monto}, fn balance ->
      Map.update(balance, moneda, monto, &(&1 + monto))
    end)
  end

  def convertir(tipos, moneda_origen, moneda_destino, monto) do
    tasa_o = Map.fetch!(tipos, moneda_origen)
    tasa_d = Map.fetch!(tipos, moneda_destino)
    tasa_o * monto / tasa_d
  end
end
