defmodule Ledger.Constantes do
  @moduledoc "Constantes compartidas del proyecto."

  @delimitador_csv_binario ?;
  @delimitador_csv ";"
  @headers_transacciones [
    "id",
    "timestamp",
    "moneda_origen",
    "moneda_destino",
    "monto",
    "cuenta_origen",
    "cuenta_destino",
    "tipo"
  ]
  @headers_moneda ["moneda", "cambio"]
  @csv_transacciones_path "./data/transacciones.csv"
  @csv_monedas_path "./data/monedas.csv"
  @default_output_path 0
  @default_moneda 0
  @tipos_validos ["alta_cuenta", "transferencia", "swap"]

  def csv_transacciones_path, do: @csv_transacciones_path
  def csv_monedas_path, do: @csv_monedas_path
  def default_output_path, do: @default_output_path
  def default_moneda, do: @default_moneda

  def delimitador_csv_binario, do: @delimitador_csv_binario
  def delimitador_csv, do: @delimitador_csv
  def headers_transacciones, do: @headers_transacciones
  def headers_moneda, do: @headers_moneda
  def tipos_validos, do: @tipos_validos
end
