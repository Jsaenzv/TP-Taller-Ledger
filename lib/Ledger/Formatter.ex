defmodule Ledger.Formatter do
  alias Ledger.Constantes

  def formattear_transacciones(transacciones) do
    transacciones
    |> Enum.map(fn fila -> Enum.map(Constantes.headers_transacciones(), &fila[&1]) end)
    |> Enum.map(fn fila -> Enum.join(fila, Constantes.delimitador_csv()) end)
    |> Enum.join("\n")
  end

  def formattear_balance(balance) do
    balance
    |> Enum.map(fn {moneda, monto} ->
      "#{moneda};#{:erlang.float_to_binary(monto, decimals: 6)}"
    end)
    |> Enum.sort()
    |> Enum.join("\n")
  end
end
