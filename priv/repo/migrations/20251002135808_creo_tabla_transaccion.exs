defmodule Ledger.Repo.Migrations.CreoTablaTransaccion do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :monto, :float, null: false
      add :moneda_origen_id, references(:monedas, on_delete: :restrict), null: false
      add :moneda_destino_id, references(:monedas, on_delete: :restrict)
      add :cuenta_origen, references(:users, on_delete: :restrict), null: false
      add :cuenta_destino, references(:users, on_delete: :restrict)
      add :tipo, :string, null: false
      timestamps()
    end

    create index(:transacciones, [:moneda_origen_id])
end

end
