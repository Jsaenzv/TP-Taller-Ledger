defmodule Ledger.Repo.Migrations.CreoTablaMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre, :string, null: false
      add :precio_en_dolares, :float, null: false
      timestamps()
    end
    create unique_index(:monedas, [:nombre])
    create constraint(:monedas, :precio_en_dolares_no_negativo, check: "precio_en_dolares >= 0")
    create constraint(:monedas, :nombre_formato, check: "char_length(nombre) BETWEEN 3 AND 4 AND nombre = upper(nombre)")
  end
end
