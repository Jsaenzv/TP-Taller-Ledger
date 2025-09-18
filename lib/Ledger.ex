defmodule Ledger do
  @headers_transacciones [
    "id",
    "timestamp",
    "moneda_origen",
    "moneda_destino",
    "monto",
    "cuenta_origen",
    "cuenta_destino",
    "tipo"
  ]
  @headers_moneda ["moneda", "cambio"]
  @csv_transacciones_path "./data/transacciones.csv"
  @csv_monedas_path "./data/monedas.csv"
  @delimitador_csv ";"
  @default_output_path 0
  @default_moneda 0

  def main(["transacciones" | flags]) do
    params = parsear_flags(flags)

    output_path = Map.get(params, "output_path", @default_output_path)
    input_path = Map.get(params, "input_path", @csv_transacciones_path)

    params_filtrados = Map.drop(params, ["output_path", "input_path"])
    output = transacciones(params_filtrados, input_path)

    case output_path do
      @default_output_path -> IO.puts(formattear_transacciones(output))
      _ -> File.write!(output_path, formattear_transacciones(output))
    end
  end

  def main(["balance" | flags]) do
    params = parsear_flags(flags)

    output_path = Map.get(params, "output_path", @default_output_path)
    input_path = Map.get(params, "input_path", @csv_transacciones_path)

    params_filtrados = Map.drop(params, ["output_path", "input_path"])
    output = balance(params_filtrados, input_path)

    case output_path do
      @default_output_path ->
        IO.puts(formattear_balance(output))

      _ ->
        File.write!(output_path, formattear_balance(output))
    end
  end

  defp parsear_flags(flags) do
    Enum.map(flags, fn flag ->
      String.split(flag, "=", parts: 2)
      |> List.to_tuple()
    end)
    |> Enum.map(fn {clave, valor} ->
      case {clave, valor} do
        {"-c1", valor} -> {"cuenta_origen", valor}
        {"-c2", valor} -> {"cuenta_destino", valor}
        {"-t", valor} -> {"input_path", valor}
        {"-o", valor} -> {"output_path", valor}
        {"-m", valor} -> {"moneda", valor}
        _ -> raise ArgumentError, message: "Flag no soportado: #{clave}"
      end
    end)
    |> Map.new()
  end

  defp transacciones(params, input_path) do
    tipos_de_cambio =
      case leer_csv(@csv_monedas_path, @headers_moneda) do
        {:ok, tipos_de_cambio} ->
          Enum.reduce(tipos_de_cambio, %{}, fn %{"moneda" => moneda, "cambio" => cambio}, acc ->
            Map.put(acc, moneda, parse_float(cambio))
          end)

        {:error, razon} ->
          raise(razon)
      end

    transacciones =
      case leer_csv(input_path, @headers_transacciones) do
        {:ok, filas} -> filas
        {:error, razon} -> raise(razon)
      end

    case validar_transacciones(transacciones, tipos_de_cambio) do
      {:error, razon} -> raise(razon)
      :ok -> nil
    end

    transacciones_filtradas =
      if map_size(params) == 0 do
        transacciones
      else
        transacciones
        |> Enum.filter(fn fila ->
          Enum.all?(params, fn {flag, valor} -> fila[flag] == valor end)
        end)
      end

    transacciones_filtradas
  end

  defp balance(params, input_path) do
    moneda = Map.get(params, "moneda", @default_moneda)
    params = Map.delete(params, "moneda")

    tipos_de_cambio =
      case leer_csv(@csv_monedas_path, @headers_moneda) do
        {:ok, tipos_de_cambio} ->
          Enum.reduce(tipos_de_cambio, %{}, fn %{"moneda" => moneda, "cambio" => cambio}, acc ->
            Map.put(acc, moneda, parse_float(cambio))
          end)

        {:error, razon} ->
          raise(razon)
      end

    transacciones =
      case leer_csv(input_path, @headers_transacciones) do
        {:ok, filas} -> filas
        {:error, razon} -> raise(razon)
      end

    case validar_transacciones(transacciones, tipos_de_cambio) do
      {:error, razon} -> raise(razon)
      :ok -> nil
    end

    cuenta_origen =
      case Map.fetch(params, "cuenta_origen") do
        {:ok, cuenta} -> cuenta
        _ -> raise ArgumentError, "Debes incluir una cuenta origen para mostrar el balance"
      end

    transacciones_cuenta_origen = transacciones(params, input_path)

    params_cuenta_destino =
      Map.delete(params, "cuenta_origen") |> Map.put("cuenta_destino", cuenta_origen)

    transacciones_cuenta_destino = transacciones(params_cuenta_destino, input_path)

    balance =
      Enum.reduce(transacciones_cuenta_origen, %{}, fn transaccion, acc ->
        tipo = transaccion["tipo"]
        monto = parse_float(transaccion["monto"])
        moneda_origen = transaccion["moneda_origen"]
        moneda_destino = transaccion["moneda_destino"]

        case tipo do
          "transferencia" ->
            Map.update(acc, moneda_origen, -monto, fn saldo -> saldo - monto end)

          "alta_cuenta" ->
            Map.update(acc, moneda_origen, monto, fn saldo -> saldo + monto end)

          "swap" ->
            cambio_moneda_origen = Map.fetch!(tipos_de_cambio, moneda_origen)
            cambio_moneda_destino = Map.fetch!(tipos_de_cambio, moneda_destino)
            monto_destino = cambio_moneda_origen * monto / cambio_moneda_destino

            acc
            |> Map.update(moneda_origen, -monto, fn saldo -> saldo - monto end)
            |> Map.update(moneda_destino, monto_destino, fn saldo -> saldo + monto_destino end)

          _ ->
            acc
        end
      end)

    balance_final =
      Enum.reduce(transacciones_cuenta_destino, balance, fn transaccion, acc ->
        tipo = transaccion["tipo"]
        monto = parse_float(transaccion["monto"])
        moneda_origen = transaccion["moneda_origen"]
        moneda_destino = transaccion["moneda_destino"]

        case tipo do
          "transferencia" ->
            cambio_moneda_origen = Map.fetch!(tipos_de_cambio, moneda_origen)
            cambio_moneda_destino = Map.fetch!(tipos_de_cambio, moneda_destino)
            monto_destino = cambio_moneda_origen * monto / cambio_moneda_destino
            Map.update(acc, moneda_destino, monto_destino, fn saldo -> saldo + monto_destino end)

          _ ->
            acc
        end
      end)

    case moneda do
      @default_moneda ->
        balance_final

      moneda_destino ->
        balance_convertido =
          Enum.reduce(balance_final, %{}, fn {moneda_origen, saldo_moneda_origen}, acc ->
            cambio_moneda_origen = Map.fetch!(tipos_de_cambio, moneda_origen)
            cambio_moneda_destino = Map.fetch!(tipos_de_cambio, moneda_destino)

            monto_destino =
              if moneda_origen == moneda_destino,
                do: 0.0,
                else: cambio_moneda_origen * saldo_moneda_origen / cambio_moneda_destino

            Map.update(acc, moneda_destino, monto_destino, fn saldo -> saldo + monto_destino end)
          end)

        balance_convertido
    end
  end

  defp formattear_transacciones(transacciones) do
    transacciones
    |> Enum.map(fn fila -> Enum.map(@headers_transacciones, &fila[&1]) end)
    |> Enum.map(fn fila -> Enum.join(fila, @delimitador_csv) end)
    |> Enum.join("\n")
  end

  defp formattear_balance(balance) do
    balance
    |> Enum.map(fn {moneda, monto} ->
      "#{moneda};#{:erlang.float_to_binary(monto, decimals: 6)}"
    end)
    |> Enum.sort()
    |> Enum.join("\n")
  end

  def validar_transacciones(transacciones, tipos_de_cambio) do
    estado_inicial = %{cuentas_alta: MapSet.new(), balances: %{}, tipos: tipos_de_cambio}

    case reducir_validando(transacciones, estado_inicial) do
      {:ok, _estado_final} -> :ok
      {:error, razon} -> {:error, razon}
    end
  end

  defp leer_csv(path, headers) do
    case File.exists?(path) do
      true ->
        filas_csv =
          path
          |> File.stream!()
          |> CSV.decode!(headers: headers, separator: ?;)
          |> Enum.to_list()

        fila_1_si_hay_headers =
          Enum.reduce(headers, %{}, fn header, acc -> Map.put(acc, header, header) end)

        filas_parseadas =
          case filas_csv do
            [^fila_1_si_hay_headers | tail] -> tail
            mapa_csv_sin_headers -> mapa_csv_sin_headers
          end

        {:ok, filas_parseadas}

      false ->
        {:error, "Archivo no encontrado: #{path}"}
    end
  end

  defp reducir_validando(transacciones, estado_inicial) do
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

  defp validar_y_aplicar(
         fila,
         linea,
         %{cuentas_alta: cuentas, balances: balances, tipos: tipos} = estado_actual
       ) do
    with {:ok, tipo} <- campo_obligatorio(fila, "tipo"),
         :ok <- validar_tipo(tipo),
         {:ok, monto} <- parsear_monto(fila["monto"]),
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
            {:error, razon} -> {:error, "Error en la línea #{linea}, razon: #{razon}"}
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
            {:error, razon} -> {:error, "Error en la línea #{linea}, razon: #{razon}"}
          end
      end
    else
      {:error, razon} -> {:error, "Error en la línea #{linea}, razon: #{razon}"}
    end
  end

  @tipos_validos ["alta_cuenta", "transferencia", "swap"]
  defp validar_tipo(tipo) do
    case tipo in @tipos_validos do
      true -> :ok
      _otro -> {:error, "Tipo inválido '#{tipo}'"}
    end
  end

  defp campo_obligatorio(fila, campo) do
    case fila[campo] do
      nil -> {:error, "Campo obligatorio faltante: #{campo}"}
      "" -> {:error, "Campo obligatorio vacío: #{campo}"}
      v -> {:ok, v}
    end
  end

  defp validar_moneda(moneda, tipos) do
    if Map.has_key?(tipos, moneda) do
      :ok
    else
      {:error, "Moneda no listada en monedas.csv: #{moneda}"}
    end
  end

  defp parsear_monto(nil), do: {:error, "Monto ausente"}
  defp parsear_monto(monto) when is_float(monto), do: {:ok, monto}
  defp parsear_monto(monto) when is_integer(monto), do: {:ok, monto / 1}

  defp parsear_monto(monto) when is_binary(monto) do
    case Float.parse(monto) do
      {f, ""} when f >= 0 ->
        {:ok, f}

      {f, ""} when f < 0 ->
        {:error, "Monto negativo no permitido"}

      _ ->
        {:error, "Monto inválido '#{monto}'"}
    end
  end

  defp cuenta_dada_de_alta(cuentas, cuenta) do
    if MapSet.member?(cuentas, cuenta) do
      :ok
    else
      {:error, "La cuenta '#{cuenta}' no fue dada de alta previamente"}
    end
  end

  defp saldo_suficiente(balances, cuenta, moneda, monto) do
    saldo = obtener_saldo(balances, cuenta, moneda)

    if saldo >= monto do
      :ok
    else
      {:error,
       "Saldo insuficiente en '#{cuenta}' para #{moneda}. requerido=#{monto}, disponible=#{saldo}"}
    end
  end

  defp obtener_saldo(balances, cuenta, moneda) do
    balances
    |> Map.get(cuenta, %{})
    |> Map.get(moneda, 0.0)
  end

  defp sumar_balance(balances, cuenta, moneda, monto) do
    Map.update(balances, cuenta, %{moneda => monto}, fn balance ->
      Map.update(balance, moneda, monto, &(&1 + monto))
    end)
  end

  defp convertir(tipos, moneda_origen, moneda_destino, monto) do
    tasa_o = Map.fetch!(tipos, moneda_origen)
    tasa_d = Map.fetch!(tipos, moneda_destino)
    tasa_o * monto / tasa_d
  end

  defp parse_float(nil),
    do: raise(ArgumentError, message: "No se puede parsear el valor nil a float")

  defp parse_float(monto) when is_float(monto), do: monto
  defp parse_float(monto) when is_integer(monto), do: monto / 1

  defp parse_float(monto) when is_binary(monto) do
    monto
    |> Float.parse()
    |> case do
      {float, _resto} -> float
      :error -> 0.0
    end
  end
end
