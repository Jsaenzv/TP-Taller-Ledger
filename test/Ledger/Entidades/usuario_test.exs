defmodule Ledger.Entidades.UsuarioTest do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario}
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})

    usuario =
      %Usuario{}
      |> Usuario.changeset(%{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]})
      |> Repo.insert!()

    {:ok,
     usuario: usuario}
  end

  describe "changeset/2" do
    test "Ingreso usuario válido", %{usuario: usuario} do
      atributos = %{nombre: usuario.nombre, fecha_nacimiento: usuario.fecha_nacimiento}
      changeset = Usuario.changeset(%Usuario{}, atributos)
      assert changeset.valid?
      assert changeset.changes.nombre == usuario.nombre
      assert changeset.changes.fecha_nacimiento == usuario.fecha_nacimiento
      assert %{} == errores_en(changeset)
    end
  end

  test "Ingreso usuario sin nombre", %{usuario: usuario} do
    atributos = %{nombre: nil, fecha_nacimiento: usuario.fecha_nacimiento}
    changeset = Usuario.changeset(%Usuario{}, atributos)
    refute changeset.valid?
    assert %{nombre: ["Este campo es obligatorio"]} == errores_en(changeset)
  end

  test "Ingreso usuario sin fecha de nacimiento", %{usuario: usuario} do
    atributos = %{nombre: usuario.nombre, fecha_nacimiento: nil}
    changeset = Usuario.changeset(%Usuario{}, atributos)
    refute changeset.valid?
    assert %{fecha_nacimiento: ["Este campo es obligatorio"]} == errores_en(changeset)
  end

  @fecha_de_nacimiento_invalida ~D[2010-01-01]
  test "Ingreso usuario menor a 18 años", %{usuario: usuario} do
    atributos = %{nombre: usuario.nombre, fecha_nacimiento: @fecha_de_nacimiento_invalida}
    changeset = Usuario.changeset(%Usuario{}, atributos)
    refute changeset.valid?
    assert %{fecha_nacimiento: ["El usuario debe ser mayor de 18 años"]} == errores_en(changeset)
  end

  @nombre_para_test "pepito"
  test "Ingreso usuario con nombre que ya existe en la tabla", %{usuario: usuario} do
    atributos = %{nombre: @nombre_para_test, fecha_nacimiento: usuario.fecha_nacimiento}
    _usuario1 = Usuario.changeset(%Usuario{}, atributos) |> Repo.insert!()
    {:error, changeset} = Usuario.changeset(%Usuario{}, atributos) |> Repo.insert()
    refute changeset.valid?
    assert %{nombre: ["Ya existe un usuario con ese nombre"]} == errores_en(changeset)
  end

  defp errores_en(changeset) do
    traverse_errors(changeset, fn {mensaje, opciones} ->
      Enum.reduce(opciones, mensaje, fn {clave, valor}, acumulado ->
        String.replace(acumulado, "%{#{clave}}", to_string(valor))
      end)
    end)
  end
end
