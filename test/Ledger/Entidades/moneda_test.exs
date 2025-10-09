defmodule Ledger.Entidades.MonedaTest do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario}
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})

    moneda =
      %Moneda{}
      |> Moneda.changeset(%{nombre: "ARS", precio_en_dolares: 1200})
      |> Repo.insert!()

    {:ok,
     moneda: moneda}
  end

  describe "changeset/2" do
    test "Ingreso moneda válida", %{moneda: moneda} do
      atributos = %{nombre: moneda.nombre, precio_en_dolares: moneda.precio_en_dolares}
      changeset = Moneda.changeset(%Moneda{}, atributos)
      assert changeset.valid?
      assert changeset.changes.nombre == moneda.nombre
      assert changeset.changes.precio_en_dolares == moneda.precio_en_dolares
    end

    test "Ingreso moneda sin nombre", %{moneda: moneda} do
      atributos = %{nombre: nil, precio_en_dolares: moneda.precio_en_dolares}
      changeset = Moneda.changeset(%Moneda{}, atributos)
      refute changeset.valid?
      assert %{nombre: ["Este campo es obligatorio"]} == errores_en(changeset)
    end

    test "Ingreso moneda sin precio en dolares", %{moneda: moneda} do
      atributos = %{nombre: moneda.nombre, precio_en_dolares: nil}
      changeset = Moneda.changeset(%Moneda{}, atributos)
      refute changeset.valid?
      assert %{precio_en_dolares: ["Este campo es obligatorio"]} == errores_en(changeset)
    end

    @nombre_moneda "USDT"
    test "Ingreso nombre que ya existe en la tabla", %{moneda: moneda} do
      atributos = %{nombre: @nombre_moneda, precio_en_dolares: moneda.precio_en_dolares}
      _moneda1 = Moneda.changeset(%Moneda{}, atributos) |> Repo.insert!()
      {:error, changeset} = Moneda.changeset(%Moneda{}, atributos) |> Repo.insert()
      refute changeset.valid?
      assert %{nombre: ["Ya existe una moneda con ese nombre"]} == errores_en(changeset)
  end

  @nombre_mayor_a_4_letras "PESOARGENTINO"
  test "Ingreso nombre con más de 4 caracteres", %{moneda: moneda} do
    atributos = %{nombre: @nombre_mayor_a_4_letras, precio_en_dolares: moneda.precio_en_dolares}
    changeset = Moneda.changeset(%Moneda{}, atributos)
    refute changeset.valid?
    assert %{nombre: ["El nombre debe tener 3 o 4 caracteres"]} == errores_en(changeset)
  end

  @nombre_menor_a_4_letras "AR"
  test "Ingreso nombre con menos de 4 caracteres", %{moneda: moneda} do
    atributos = %{nombre: @nombre_menor_a_4_letras, precio_en_dolares: moneda.precio_en_dolares}
    changeset = Moneda.changeset(%Moneda{}, atributos)
    refute changeset.valid?
    assert %{nombre: ["El nombre debe tener 3 o 4 caracteres"]} == errores_en(changeset)
  end

  test "no permite modificar el nombre una vez creada", %{moneda: moneda} do
  changeset = Moneda.changeset(moneda, %{nombre: "EUR"})

  refute changeset.valid?
  assert %{nombre: ["no se puede modificar una vez creado"]} == errores_en(changeset)
end
end
  defp errores_en(changeset) do
    traverse_errors(changeset, fn {mensaje, opciones} ->
      Enum.reduce(opciones, mensaje, fn {clave, valor}, acumulado ->
        String.replace(acumulado, "%{#{clave}}", to_string(valor))
      end)
    end)
  end
end
