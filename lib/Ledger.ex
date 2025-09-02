defmodule Ledger do
  @csv_path "./data/transacciones.csv"
  def main(["transacciones"]) do
    transacciones()
  end

  def transacciones() do
    File.stream!(@csv_path)
    |> CSV.decode()
    |> Enum.each(fn
      {:ok, fila} -> IO.puts(Enum.join(fila, ";"))
      {:error, motivo} -> IO.puts("Error: #{motivo}")
    end
    )
  end

end
