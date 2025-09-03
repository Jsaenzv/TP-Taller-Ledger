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
  @csv_path "./data/transacciones.csv"
  @delimitador_csv ";"

  def main(["transacciones" | flags]) do
    params = parsear_flags(flags)
    transacciones(params)
  end

  def parsear_flags(flags) do
    Enum.map(flags, fn flag ->
      String.split(flag, "=", parts: 2)
      |> List.to_tuple()
    end)
    |> Enum.map(fn {clave, valor} ->
      case {clave, valor} do
        {"-c1", valor} -> {"cuenta_origen", valor}
        {"-c2", valor} -> {"cuenta_destino", valor}
        {"-t", valor} -> {:t, valor}
        {"-o", valor} -> {:o, valor}
        {"-m", valor} -> {:m, valor}
        _ -> raise ArgumentError, message: "Flag no soportado: #{clave}"
      end
    end)
    |> Map.new()
  end

  def transacciones(params) do
    path = Map.get(params, :t, @csv_path)
    params_filtrados = Map.delete(params, :t)

    filas_sin_filtrar =
      path
      |> File.stream!()
      |> CSV.decode!(headers: true, separator: ?;)

    filas_filtradas =
      if map_size(params_filtrados) == 0 do
        filas_sin_filtrar
      else
        filas_sin_filtrar
        |> Enum.filter(fn fila ->
          Enum.all?(params_filtrados, fn {flag, valor} -> fila[flag] == valor end)
        end)
      end

    Enum.each(filas_filtradas, fn fila ->
      valores = Enum.map(@headers, &fila[&1])
      IO.puts(Enum.join(valores, @delimitador_csv))
    end)
  end
end
