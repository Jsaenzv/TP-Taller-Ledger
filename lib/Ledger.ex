defmodule Ledger do
  @headers [
    "id",
    "timestamp",
    "moneda_origen",
    "moneda_destino",
    "monto",
    "cuenta_origen",
    "cuenta_destino",
    "tipo"
  ]
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
        # Para después filtrar en el map por clave
        {"-c1", valor} -> {"cuenta_origen", valor}
        # Para después filtrar en el map por clave
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
    filas_sin_filtrar =
      input_path
      |> File.stream!()
      |> CSV.decode!(headers: true, separator: ?;)

    filas_filtradas =
      if map_size(params) == 0 do
        filas_sin_filtrar
      else
        filas_sin_filtrar
        |> Enum.filter(fn fila ->
          Enum.all?(params, fn {flag, valor} -> fila[flag] == valor end)
        end)
      end

    filas_filtradas
  end

  defp balance(params, input_path) do
    # Elimino la clave "moneda" de params; Map.drop con string (binario) está deprecado
    moneda = Map.get(params, "moneda", @default_moneda)
    params = Map.delete(params, "moneda")

    tipo_de_cambio =
      @csv_monedas_path
      |> File.stream!()
      |> CSV.decode!(headers: false, separator: ?;)
      # Cada fila es ["MONEDA", "VALOR"]. Convertimos a {moneda, rate_float}.
      |> Enum.map(fn [moneda, valor] -> {moneda, parse_float(valor)} end)
      |> Enum.into(%{})

    cuenta_origen =
      case Map.fetch(params, "cuenta_origen") do
        {:ok, v} -> v
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
            cambio_moneda_origen = Map.fetch!(tipo_de_cambio, moneda_origen)
            cambio_moneda_destino = Map.fetch!(tipo_de_cambio, moneda_destino)
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
            cambio_moneda_origen = Map.fetch!(tipo_de_cambio, moneda_origen)
            cambio_moneda_destino = Map.fetch!(tipo_de_cambio, moneda_destino)
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
        Enum.reduce(balance_final, %{}, fn {moneda_origen, saldo_moneda_origen}, acc ->
          cambio_moneda_origen = Map.fetch!(tipo_de_cambio, moneda_origen)
          cambio_moneda_destino = Map.fetch!(tipo_de_cambio, moneda_destino)

          monto_destino =
            if moneda_origen == moneda_destino,
              do: 0.0,
              else: cambio_moneda_origen * saldo_moneda_origen / cambio_moneda_destino

          Map.update(acc, moneda_destino, monto_destino, fn saldo -> saldo + monto_destino end)
        end)
    end
  end

  defp formattear_transacciones(transacciones) do
    transacciones
    # Aseguro el orden (ya que Map no lo hace)
    |> Enum.map(fn fila -> Enum.map(@headers, &fila[&1]) end)
    # Uno cada valor con el delimitador
    |> Enum.map(fn fila -> Enum.join(fila, @delimitador_csv) end)
    # Uno cada fila con \n
    |> Enum.join("\n")
  end

  defp formattear_balance(balance) do
    balance
    |> Enum.map(fn {moneda, monto} ->
      "#{moneda};#{:erlang.float_to_binary(monto, decimals: 6)}"
    end)
    # Orden determinístico para facilitar tests reproducibles
    |> Enum.sort()
    |> Enum.join("\n")
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
