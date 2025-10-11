defmodule Ledger.EntidadesTests do
  use ExUnit.Case, async: false

  alias Ledger.Entidades.{Moneda, Transaccion, Usuario, FuncionesDB}
  alias Ledger.Entidades
  alias Ledger.Repo

  import Ecto.Changeset

  setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ledger.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Ledger.Repo, {:shared, self()})
  Repo.delete_all(Usuario)
  :ok
end

@nombre_default "juan"
@nombre_alternativo "pedro"
@fecha_nacimiento_default ~D[1990-01-01]
@fecha_nacimiento_alternativa ~D[2000-01-01]
@fecha_nacimiento_invalida ~D[2020-01-01]


  describe "crear_usuario/2" do
    test "Ingreso usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      assert usuario_creado.nombre == @nombre_default
      assert usuario_creado.fecha_nacimiento == @fecha_nacimiento_default

    end

    test "Ingreso usuario inválido" do
      assert {:error, changeset} = Entidades.crear_usuario(nil, nil)
      refute changeset.valid?
      assert %{nombre: ["Este campo es obligatorio"], fecha_nacimiento: ["Este campo es obligatorio"]} = FuncionesDB.errores_en(changeset)

      assert {:error, changeset} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_invalida)
      refute changeset.valid?
      assert %{fecha_nacimiento: ["El usuario debe ser mayor de 18 años"]} = FuncionesDB.errores_en(changeset)

    end
  end

  describe "editar_usuario/2" do

    test "Edito usuario" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      atributos = %{nombre: @nombre_alternativo, fecha_nacimiento: @fecha_nacimiento_alternativa}
      {:ok, usuario_editado} = Entidades.editar_usuario(usuario_creado, atributos)
      assert usuario_editado.nombre == @nombre_alternativo
      assert usuario_editado.fecha_nacimiento == @fecha_nacimiento_alternativa

    end
  end

  describe "eliminar_usuario/1" do
    test "elimino usuario válido" do
      {:ok, usuario_creado} = Entidades.crear_usuario(@nombre_default, @fecha_nacimiento_default)
      assert {:ok, usuario_eliminado} = Entidades.eliminar_usuario(usuario_creado)
      assert usuario_eliminado.id == usuario_creado.id
      assert Repo.get(Usuario, usuario_creado.id) == nil
    end

    test "elimino usuario inexistente en la base de datos" do
      usuario_falso = %Usuario{id: -1, nombre: "fantasma", fecha_nacimiento: ~D[1980-01-01]}
      assert {:error, :not_found} = Entidades.eliminar_usuario(usuario_falso)
    end
  end
end
