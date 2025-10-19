defmodule Ledger.Validador do

  def validar_flags(flags, obligatorios, permitidos \\ []) do
    keys = Map.keys(flags)

    faltantes =
      obligatorios
      |> Enum.reject(&Map.has_key?(flags, &1))

    vacios = Enum.filter(obligatorios, &(Map.get(flags, &1) in [nil, ""]))

    extras =
      keys
      |> Enum.reject(&(&1 in obligatorios or &1 in permitidos))

    cond do
      faltantes != [] ->
        {:error, "Faltan flags obligatorios: #{Enum.join(faltantes, ", ")}"}

      vacios != [] ->
        {:error, "Los campos obligatorios no pueden ser vacíos: #{Enum.join(vacios, ", ")}"}

      extras != [] ->
        permitidos_totales = (obligatorios ++ permitidos) |> Enum.uniq()

        {:error,
         "Flags no permitidos: #{Enum.join(extras, ", ")}. Permitidos: #{Enum.join(permitidos_totales, ", ")}"}

      true ->
        :ok
    end
  end
end
