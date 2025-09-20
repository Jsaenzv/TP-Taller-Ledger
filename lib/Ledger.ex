defmodule Ledger do
  alias Ledger.CSV
  alias Ledger.Formatter
  alias Ledger.Constantes
  alias Ledger.Parser
  alias Ledger.Validador

  def main(["transacciones" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :transacciones) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    output_path = Map.get(params, "output_path", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["output_path", "input_path"])
    output = transacciones(params_filtrados, input_path)

    default_output_path = Constantes.default_output_path()

    case output_path do
      ^default_output_path -> IO.puts(Formatter.formattear_transacciones(output))
      _ -> File.write!(output_path, Formatter.formattear_transacciones(output))
    end
  end

  def main(["balance" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :balance) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    output_path = Map.get(params, "output_path", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["output_path", "input_path"])
    output = balance(params_filtrados, input_path)

    default_output_path = Constantes.default_output_path()

    case output_path do
      ^default_output_path ->
        IO.puts(Formatter.formattear_balance(output))

      _ ->
        File.write!(output_path, Formatter.formattear_balance(output))
    end
  end

  defp transacciones(params, input_path) do
    tipos_de_cambio =
      case CSV.leer_csv(Constantes.csv_monedas_path(), Constantes.headers_moneda()) do
        {:ok, tipos_de_cambio} ->
          Enum.reduce(tipos_de_cambio, %{}, fn %{"moneda" => moneda, "cambio" => cambio}, acc ->
            Map.put(acc, moneda, Parser.parse_float(cambio))
          end)

        {:error, razon} ->
          raise(razon)
      end

    transacciones =
      case CSV.leer_csv(input_path, Constantes.headers_transacciones()) do
        {:ok, filas} -> filas
        {:error, razon} -> raise(razon)
      end

    case Validador.validar_transacciones(transacciones, tipos_de_cambio) do
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
    moneda = Map.get(params, "moneda", Constantes.default_moneda())
    params = Map.delete(params, "moneda")

    tipos_de_cambio =
      case CSV.leer_csv(Constantes.csv_monedas_path(), Constantes.headers_moneda()) do
        {:ok, tipos_de_cambio} ->
          Enum.reduce(tipos_de_cambio, %{}, fn %{"moneda" => moneda, "cambio" => cambio}, acc ->
            Map.put(acc, moneda, Parser.parse_float(cambio))
          end)

        {:error, razon} ->
          raise(razon)
      end

    transacciones =
      case CSV.leer_csv(input_path, Constantes.headers_transacciones()) do
        {:ok, filas} -> filas
        {:error, razon} -> raise(razon)
      end

    case Validador.validar_transacciones(transacciones, tipos_de_cambio) do
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
        monto = Parser.parse_float(transaccion["monto"])
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
        monto = Parser.parse_float(transaccion["monto"])
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

    default_moneda = Constantes.default_moneda()

    case moneda do
      ^default_moneda ->
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
end
