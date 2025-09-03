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
  @default_output_path 0

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
        # Para después filtrar en el map por clave
        {"-c1", valor} -> {"cuenta_origen", valor}
        # Para después filtrar en el map por clave
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
    output_path = Map.get(params, :o, @default_output_path)

    params_filtrados = Map.drop(params, [:t, :o])

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

    output =
      filas_filtradas
      # Aseguro el orden (ya que Map no lo hace)
      |> Enum.map(fn fila -> Enum.map(@headers, &fila[&1]) end)
      # Uno cada valor con el delimitador
      |> Enum.map(fn fila -> Enum.join(fila, @delimitador_csv) end)
      # Uno cada fila con \n
      |> Enum.join("\n")

    case output_path do
      0 -> IO.puts(output)
      _ -> File.write!(output_path, output)
    end
  end
end
