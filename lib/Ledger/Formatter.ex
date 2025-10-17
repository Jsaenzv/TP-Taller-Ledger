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
