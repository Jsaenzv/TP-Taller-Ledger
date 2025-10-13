defmodule Ledger.CLI do
  alias Ledger.Constantes
  alias Ledger.Parser
  alias Ledger.Validador
  alias Ledger.Transacciones
  alias Ledger.Balance
  alias Ledger.Output
  alias Ledger.Entidades

  def main(["transacciones" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :transacciones) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    output_path = Map.get(params, "id_usuario_origen", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["id_usuario_origen", "input_path"])
    output = Transacciones.transacciones(params_filtrados, input_path)

    Output.output_transacciones(output, output_path)
  end

  def main(["balance" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :balance) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    output_path = Map.get(params, "id_usuario_origen", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["id_usuario_origen", "input_path"])
    output = Balance.balance(params_filtrados, input_path)

    Output.output_balance(output, output_path)
  end

  def main(["crear_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :crear_usuario) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    atributos_usuario = %{
      nombre: Map.get(params, "nombre_usuario"),
      fecha_nacimiento: Map.get(params, "fecha_nacimiento")
    }

    Entidades.crear_usuario(atributos_usuario)
  end
end
