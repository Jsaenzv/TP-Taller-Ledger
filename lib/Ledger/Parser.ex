defmodule Ledger.Parser do
  def parse_float(nil),
    do: raise(ArgumentError, message: "No se puede parsear el valor nil a float")

  def parse_float(monto) when is_float(monto), do: monto
  def parse_float(monto) when is_integer(monto), do: monto / 1

  def parse_float(monto) when is_binary(monto) do
    monto
    |> Float.parse()
    |> case do
      {float, _resto} -> float
      :error -> 0.0
    end
  end

  def parsear_monto(nil), do: {:error, "Monto ausente"}
  def parsear_monto(monto) when is_float(monto), do: {:ok, monto}
  def parsear_monto(monto) when is_integer(monto), do: {:ok, monto / 1}

  def parsear_monto(monto) when is_binary(monto) do
    case Float.parse(monto) do
      {f, ""} when f >= 0 ->
        {:ok, f}

      {f, ""} when f < 0 ->
        {:error, "Monto negativo no permitido"}

      _ ->
        {:error, "Monto inválido '#{monto}'"}
    end
  end

  def parsear_flags(flags) do
    Enum.map(flags, fn flag ->
      String.split(flag, "=", parts: 2)
      |> List.to_tuple()
    end)
    |> Enum.map(fn {clave, valor} ->
      case {clave, valor} do
        {"-u", valor} -> {"id_usuario", valor}
        {"-a", valor} -> {"monto", valor}
        {"-c1", valor} -> {"cuenta_origen", valor}
        {"-c2", valor} -> {"cuenta_destino", valor}
        {"-t", valor} -> {"input_path", valor}
        {"-id", valor} -> {"id_transaccion", valor}
        {"-o", valor} -> {"id_usuario_origen", valor}
        {"-d", valor} -> {"id_usuario_destino", valor}
        {"-m", valor} -> {"moneda", valor}
        {"-mo", valor} -> {"id_moneda_origen", valor}
        {"-md", valor} -> {"id_moneda_destino", valor}
        _ -> raise ArgumentError, message: "Flag no soportado: #{clave}"
      end
    end)
    |> Map.new()
  end
end
