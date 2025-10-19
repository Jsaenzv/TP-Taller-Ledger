defmodule Ledger.Formatter do
  alias Ledger.Entidades.Cuenta
  alias Ledger.Entidades

  def formattear_balance(cuentas) when is_list(cuentas) do
    cuentas
    |> Enum.map(fn %Cuenta{} = c ->
      moneda = Entidades.obtener_moneda(c.moneda_id)
      usuario = Entidades.obtener_usuario(c.usuario_id)

      balance = :erlang.float_to_binary(c.balance, decimals: 6)

      [
        "Id usuario: #{usuario.id}",
        "Nombre usuario: #{usuario.nombre}",
        "Nombre moneda: #{moneda.nombre}",
        "Balance: #{balance}"
      ]
      |> Enum.join("\n")
    end)
    |> Enum.join("\n\n")
  end

  def formattear_usuario(%Ledger.Entidades.Usuario{} = usuario) do
    [
      "Usuario:",
      "  id: #{usuario.id}",
      "  nombre: #{usuario.nombre}",
      "  fecha_nacimiento: #{usuario.fecha_nacimiento}",
      "  creado_el: #{usuario.inserted_at}",
      "  actualizado_el: #{usuario.updated_at}"
    ]
    |> Enum.join("\n")
  end

  def formatear_moneda(%Ledger.Entidades.Moneda{} = moneda) do
    [
      "Moneda:",
      "  id: #{moneda.id}",
      "  nombre: #{moneda.nombre}",
      "  precio_en_dolares: #{:erlang.float_to_binary(moneda.precio_en_dolares, decimals: 6)}",
      "  creado_el: #{moneda.inserted_at}",
      "  actualizado_el: #{moneda.updated_at}"
    ]
    |> Enum.join("\n")
  end

  def formattear_transaccion(%Ledger.Entidades.Transaccion{} = transaccion) do
    [
      "Transaccion:",
      "  id: #{transaccion.id}",
      "  cuenta_origen: #{transaccion.cuenta_origen_id}",
      "  moneda_id: #{transaccion.moneda_origen_id}",
      "  tipo: #{transaccion.tipo}",
      "  monto: #{:erlang.float_to_binary(transaccion.monto, decimals: 6)}",
      "  creado_el: #{transaccion.inserted_at}",
      "  actualizado_el: #{transaccion.updated_at}"
    ]
    |> Enum.join("\n")
  end
end
