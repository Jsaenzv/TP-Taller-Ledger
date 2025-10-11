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


  describe "crear_usuario/2" do
    test "Ingreso usuario válido" do
      usuario =
      %Usuario{nombre: "juan", fecha_nacimiento: ~D[1990-01-01]}

      {:ok, usuario_creado} = Entidades.crear_usuario("juan", ~D[1990-01-01])
      assert usuario_creado.nombre == usuario.nombre
      assert usuario_creado.fecha_nacimiento == usuario.fecha_nacimiento

    end
  end

end
