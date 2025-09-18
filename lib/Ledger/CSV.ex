defmodule Ledger.CSV do
  alias Ledger.Constantes

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
end
