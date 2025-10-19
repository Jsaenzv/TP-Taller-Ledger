defmodule Ledger.Output do
  alias Ledger.Formatter
  alias Ledger.Entidades

  def output_transacciones([]) do
    IO.puts("No hay transacciones")
  end

  def output_transacciones(transacciones) when is_list(transacciones) do
    Enum.each(transacciones, fn transaccion ->
      IO.puts(Formatter.formattear_transaccion(transaccion))
    end)
  end

  def output_balance(balance) do
    IO.puts(Formatter.formattear_balance(balance))
  end

  def output_ver_usuario(usuario) do
    case usuario do
      nil -> IO.puts("Usuario no encontrado")
      _ -> IO.puts(Formatter.formattear_usuario(usuario))
    end
  end

  def output_ver_moneda(id_moneda) do
    case Entidades.obtener_moneda(id_moneda) do
      nil -> IO.puts("Moneda no encontrada")
      moneda -> IO.puts(Formatter.formatear_moneda(moneda))
    end
  end

  def output_ver_transaccion(id_transaccion) do
    case Entidades.obtener_transaccion(id_transaccion) do
      nil -> IO.puts("Transacción no encontrada")
      transaccion -> IO.puts(Formatter.formattear_transaccion(transaccion))
    end
  end
end
