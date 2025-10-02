defmodule Ledger.Repo.Migrations.RenameUsersToUsuarios do
  use Ecto.Migration

  def change do
    rename table(:users), to: table(:usuarios)
  end
end
