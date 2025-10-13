defmodule Ledger.Transacciones do
  alias Ledger.CSV
  alias Ledger.Constantes
  alias Ledger.Parser
  alias Ledger.Validador

  def transacciones(params, input_path) do
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
end
