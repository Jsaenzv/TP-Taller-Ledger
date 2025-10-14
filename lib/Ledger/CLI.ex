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

    output_path = Map.get(params, "id_usuario_origen/output_path", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["id_usuario_origen/output_path", "input_path"])
    output = Transacciones.transacciones(params_filtrados, input_path)

    Output.output_transacciones(output, output_path)
  end

  def main(["balance" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :balance) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    output_path = Map.get(params, "id_usuario_origen/output_path", Constantes.default_output_path())
    input_path = Map.get(params, "input_path", Constantes.csv_transacciones_path())

    params_filtrados = Map.drop(params, ["id_usuario_origen/output_path", "input_path"])
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
      nombre: Map.get(params, "nombre"),
      fecha_nacimiento: Map.get(params, "fecha_nacimiento")
    }

    Entidades.crear_usuario(atributos_usuario)
  end

  def main(["editar_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :editar_usuario) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    nombre = Map.get(params, "nombre")
    fecha_nacimiento = Map.get(params, "fecha_nacimiento")

    atributos_usuario =
      %{}
      |> (fn atributos -> if nombre, do: Map.put(atributos, :nombre, nombre), else: atributos end).()
      |> (fn atributos ->
            if fecha_nacimiento,
              do: Map.put(atributos, :fecha_nacimiento, fecha_nacimiento),
              else: atributos
          end).()

    id_usuario = Map.get(params, "id_usuario")
    Entidades.editar_usuario(id_usuario, atributos_usuario)
  end

  def main(["eliminar_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :eliminar_usuario) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    id_usuario = Map.get(params, "id_usuario")
    Entidades.eliminar_usuario(id_usuario)
  end

  def main(["ver_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :ver_usuario) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    usuario = Entidades.obtener_usuario(Map.get(params, "id_usuario"))
    Output.output_ver_usuario(usuario)
  end

  def main(["crear_moneda" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, :crear_moneda) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    atributos_moneda = %{
      nombre: Map.get(params, "nombre"),
      precio_en_dolares: Map.get(params, "precio_en_dolares")
    }

    Entidades.crear_moneda(atributos_moneda)
  end
end
