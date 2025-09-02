defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  @ejecutable Path.join(File.cwd!(), "ledger")
  @csv_path "./data/transacciones.csv"

  test "ledger transacciones" do
    {output, status} = System.cmd(@ejecutable, ["transacciones"])
    assert status == 0
    esperado = File.read!(@csv_path)
    assert String.trim_trailing(output, "\n") == String.trim_trailing(esperado, "\n") # trim_trailing elimina "\n" del final si es que esta, caso contrario devuelve el mismo string
  end
end
