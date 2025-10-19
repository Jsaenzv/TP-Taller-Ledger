defmodule Ledger.Aplicacion do
  use Application

  @impl true
  def start(_tipos, _args) do
    hijos = [
      Ledger.Repo
    ]

    opciones = [strategy: :one_for_one, name: Ledger.Supervisor]
    Supervisor.start_link(hijos, opciones)
  end
end
