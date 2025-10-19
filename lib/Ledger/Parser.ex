defmodule Ledger.Parser do

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
        {"-id", valor} -> {"id", valor}
        {"-o", valor} -> {"id_usuario_origen", valor}
        {"-d", valor} -> {"id_usuario_destino", valor}
        {"-m", valor} -> {"moneda", valor}
        {"-mo", valor} -> {"id_moneda_origen", valor}
        {"-md", valor} -> {"id_moneda_destino", valor}
        {"-n", valor} -> {"nombre", valor}
        {"-b", valor} -> {"fecha_nacimiento", valor}
        {"-p", valor} -> {"precio_en_dolares", valor}
        _ -> raise ArgumentError, message: "Flag no soportado: #{clave}"
      end
    end)
    |> Map.new()
  end
end
