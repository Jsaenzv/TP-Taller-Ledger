defmodule Ledger.Output do
  alias Ledger.Formatter
  alias Ledger.Constantes
  alias Ledger.Entidades

  def output_transacciones(output, path) do
    default_output_path = Constantes.default_output_path()

    case path do
      ^default_output_path -> IO.puts(Formatter.formattear_transacciones(output))
      _ -> File.write!(path, Formatter.formattear_transacciones(output))
    end
  end

  def output_balance(output, path) do
    default_output_path = Constantes.default_output_path()

    case path do
      ^default_output_path ->
        IO.puts(Formatter.formattear_balance(output))

      _ ->
        File.write!(path, Formatter.formattear_balance(output))
    end
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
end
