defmodule Ledger.Validador do
  alias Ledger.Parser
  alias Ledger.Constantes

  def validar_flags(flags, obligatorios, permitidos \\ []) do
    keys = Map.keys(flags)

    faltantes =
      obligatorios
      |> Enum.reject(&Map.has_key?(flags, &1))

    vacios = Enum.filter(obligatorios, &(Map.get(flags, &1) in [nil, ""]))

    extras =
      keys
      |> Enum.reject(&(&1 in obligatorios or &1 in permitidos))

    cond do
      faltantes != [] ->
        {:error, "Faltan flags obligatorios: #{Enum.join(faltantes, ", ")}"}

      vacios != [] ->
        {:error, "Los campos obligatorios no pueden ser vacíos: #{Enum.join(vacios, ", ")}"}

      extras != [] ->
        permitidos_totales = (obligatorios ++ permitidos) |> Enum.uniq()

        {:error,
         "Flags no permitidos: #{Enum.join(extras, ", ")}. Permitidos: #{Enum.join(permitidos_totales, ", ")}"}

      true ->
        :ok
    end
  end

  def validar_campo_vacio(flags, campo) do
    case Map.get(flags, campo) do
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
