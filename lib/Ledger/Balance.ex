defmodule Ledger.Balance do
  alias Ledger.CSV
  alias Ledger.Constantes
  alias Ledger.Parser
  alias Ledger.Validador
  alias Ledger.Transacciones

  def balance(params, input_path) do
    moneda = Map.get(params, "moneda", Constantes.default_moneda())
    params = Map.delete(params, "moneda")

    tipos_de_cambio = CSV.obtener_tipos_de_cambio()

    transacciones = CSV.obtener_transacciones(input_path)

    case Validador.validar_transacciones(transacciones, tipos_de_cambio) do
      {:error, razon} -> raise(razon)
      :ok -> nil
    end

    cuenta_origen =
      case Map.fetch(params, "cuenta_origen") do
        {:ok, cuenta} -> cuenta
        _ -> raise ArgumentError, "Debes incluir una cuenta origen para mostrar el balance"
      end

    transacciones_cuenta_origen = Transacciones.transacciones(params, input_path)

    params_cuenta_destino =
      Map.delete(params, "cuenta_origen") |> Map.put("cuenta_destino", cuenta_origen)

    transacciones_cuenta_destino = Transacciones.transacciones(params_cuenta_destino, input_path)

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
