defmodule Ledger.Repo.Migrations.CreoTablaUsuario do
  use Ecto.Migration

  def change do
    create table (:users) do
      add :nombre, :string, null: false
      add :fecha_nacimiento, :date, null: false
      timestamps()
    end

    create unique_index(:users, [:nombre])
  end
end
