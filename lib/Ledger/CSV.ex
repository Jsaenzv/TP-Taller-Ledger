defmodule Ledger.CSV do
  alias Ledger.Constantes
  alias Ledger.Parser

  def leer_csv(path, headers) do
    case File.exists?(path) do
      true ->
        filas_csv =
          path
          |> File.stream!()
          |> CSV.decode!(headers: headers, separator: Constantes.delimitador_csv_binario())
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

  def obtener_tipos_de_cambio(input_path \\ Constantes.csv_monedas_path) do
    case leer_csv(input_path, Constantes.headers_moneda()) do
        {:ok, tipos_de_cambio} ->
          Enum.reduce(tipos_de_cambio, %{}, fn %{"moneda" => moneda, "cambio" => cambio}, acc ->
            Map.put(acc, moneda, Parser.parse_float(cambio))
          end)

        {:error, razon} ->
          raise(razon)
      end
  end

  def obtener_transacciones(input_path \\ Constantes.csv_transacciones_path()) do
    case leer_csv(input_path, Constantes.headers_transacciones()) do
        {:ok, filas} -> filas
        {:error, razon} -> raise(razon)
      end
  end
end
