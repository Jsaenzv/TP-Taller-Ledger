defmodule Ledger.Repo.Migrations.CreoTablaCuentas do
  use Ecto.Migration

  def change do
  create table(:cuentas) do
    add :usuario_id, references(:usuarios, on_delete: :delete_all), null: false
    add :moneda_id, references(:monedas, on_delete: :delete_all), null: false
    timestamps()
  end

  create unique_index(:cuentas, [:usuario_id, :moneda_id])
end

end
