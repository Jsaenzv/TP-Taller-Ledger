defmodule Ledger.Entidades.FuncionesDB do
  import Ecto.Changeset, only: [traverse_errors: 2]

  def errores_en(changeset) do
      traverse_errors(changeset, fn {mensaje, opciones} ->
        Enum.reduce(opciones, mensaje, fn {clave, valor}, acumulado ->
          String.replace(acumulado, "%{#{clave}}", to_string(valor))
        end)
      end)
    end
end
