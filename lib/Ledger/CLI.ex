defmodule Ledger.CLI do
  alias Ledger.Parser
  alias Ledger.Validador
  alias Ledger.Output
  alias Ledger.Entidades

  def main(["transacciones" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, [], [
           "cuenta_origen",
           "cuenta_destino"
         ]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    transacciones = Entidades.obtener_transacciones(params)

    Output.output_transacciones(transacciones)
  end

  def main(["balance" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["cuenta_origen"], ["moneda"]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    usuario = Entidades.obtener_usuario(Map.get(params, "cuenta_origen"))
    id_moneda = Map.get(params, "moneda")

    cuentas = Entidades.obtener_cuentas(%{usuario_id: usuario.id, moneda_id: id_moneda})

    Output.output_balance(cuentas)
  end

  def main(["crear_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["nombre", "fecha_nacimiento"]) do
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

    case Validador.validar_flags(params, ["id_usuario"], ["nombre", "fecha_nacimiento"]) do
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

    case Validador.validar_flags(params, ["id_usuario"]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    id_usuario = Map.get(params, "id_usuario")
    Entidades.eliminar_usuario(id_usuario)
  end

  def main(["ver_usuario" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id_usuario"]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    usuario = Entidades.obtener_usuario(Map.get(params, "id_usuario"))
    Output.output_ver_usuario(usuario)
  end

  def main(["crear_moneda" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["nombre", "precio_en_dolares"]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    atributos_moneda = %{
      nombre: Map.get(params, "nombre"),
      precio_en_dolares: Map.get(params, "precio_en_dolares")
    }

    Entidades.crear_moneda(atributos_moneda)
  end

  def main(["editar_moneda" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id", "precio_en_dolares"]) do
      {:error, razon} -> raise("Error al válidar los flags. #{razon}")
      _ -> nil
    end

    id_moneda = Map.get(params, "id")

    precio_en_dolares = Map.get(params, "precio_en_dolares")

    Entidades.editar_moneda(id_moneda, precio_en_dolares)
  end

  def main(["borrar_moneda" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id"]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    id_moneda = Map.get(params, "id")

    Entidades.eliminar_moneda(id_moneda)
  end

  def main(["ver_moneda" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id"]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    id_moneda = Map.get(params, "id")

    Output.output_ver_moneda(id_moneda)
  end

  def main(["alta_cuenta" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id_usuario", "moneda", "monto"]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    atributos = %{
      monto: Map.get(params, "monto"),
      tipo: "alta_cuenta",
      moneda_origen_id: Map.get(params, "moneda"),
      cuenta_origen: Map.get(params, "id_usuario")
    }

    Entidades.crear_transaccion(atributos)
  end

  def main(["realizar_transferencia" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, [
           "id_usuario_origen",
           "id_usuario_destino",
           "monto",
           "moneda"
         ]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    atributos = %{
      monto: Map.get(params, "monto"),
      tipo: "transferencia",
      moneda_origen_id: Map.get(params, "moneda"),
      moneda_destino_id: Map.get(params, "moneda"),
      cuenta_origen: Map.get(params, "id_usuario_origen"),
      cuenta_destino: Map.get(params, "id_usuario_destino")
    }

    Entidades.crear_transaccion(atributos)
  end

  def main(["realizar_swap" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, [
           "id_usuario",
           "monto",
           "id_moneda_origen",
           "id_moneda_destino"
         ]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    atributos = %{
      monto: Map.get(params, "monto"),
      tipo: "swap",
      moneda_origen_id: Map.get(params, "id_moneda_origen"),
      moneda_destino_id: Map.get(params, "id_moneda_destino"),
      cuenta_origen: Map.get(params, "id_usuario")
    }

    Entidades.crear_transaccion(atributos)
  end

  def main(["deshacer_transaccion" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id"]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    id_transaccion = Map.get(params, "id")
    Entidades.deshacer_transaccion(id_transaccion)
  end

  def main(["ver_transaccion" | flags]) do
    params = Parser.parsear_flags(flags)

    case Validador.validar_flags(params, ["id"]) do
      {:error, razon} -> raise("Error al validar los flags. #{razon}")
      _ -> nil
    end

    id_transaccion = Map.get(params, "id")

    Output.output_ver_transaccion(id_transaccion)
  end
end
