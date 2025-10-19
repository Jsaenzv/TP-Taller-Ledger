defmodule Ledger.Repo.Migrations.ModificoTablaCuentas do
  use Ecto.Migration

  def change do
    alter table(:cuentas) do
      add(:balance, :float, null: false, default: 0.0)
    end
  end
end
