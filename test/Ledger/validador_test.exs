defmodule Ledger.ValidadorTest do
  use ExUnit.Case, async: true

  alias Ledger.Validador

  describe "validar_flags/3" do
    test "retorna :ok cuando los flags obligatorios están presentes y permitidos" do
      flags = %{"flag1" => "valor1", "flag2" => "valor2", "extra" => "val"}
      assert :ok == Validador.validar_flags(flags, ["flag1", "flag2"], ["extra"])
    end

    test "detecta faltantes" do
      flags = %{"flag1" => "valor1"}
      assert {:error, mensaje} = Validador.validar_flags(flags, ["flag1", "flag2"], [])
      assert mensaje =~ "Faltan flags obligatorios: flag2"
    end

    test "detecta vacíos" do
      flags = %{"flag1" => "", "flag2" => "valor"}
      assert {:error, mensaje} = Validador.validar_flags(flags, ["flag1", "flag2"], [])
      assert mensaje =~ "Los campos obligatorios no pueden ser vacíos: flag1"
    end

    test "detecta extras no permitidos" do
      flags = %{"flag1" => "valor", "flag2" => "valor", "extra" => "val"}
      assert {:error, mensaje} = Validador.validar_flags(flags, ["flag1"], ["flag2"])
      assert mensaje =~ "Flags no permitidos: extra"
    end
  end

  describe "validar_campo_vacio/2" do
    test "retorna :ok cuando el campo está ausente" do
      assert :ok == Validador.validar_campo_vacio(%{}, "campo")
    end

    test "retorna :ok cuando el campo es nil" do
      assert :ok == Validador.validar_campo_vacio(%{"campo" => nil}, "campo")
    end

    test "retorna error cuando tiene valor" do
      assert {:error, "Campo campo debe estar vacío."} ==
               Validador.validar_campo_vacio(%{"campo" => "valor"}, "campo")
    end
  end

  describe "validar_transacciones/2" do
    setup do
      tipos = %{"USD" => 1.0, "ARS" => 0.001}

      {:ok, tipos: tipos}
    end

    test "acepta una secuencia válida", %{tipos: tipos} do
      transacciones = [
        %{
          "tipo" => "alta_cuenta",
          "monto" => "100",
          "moneda_origen" => "USD",
          "cuenta_origen" => "userA"
        },
        %{
          "tipo" => "alta_cuenta",
          "monto" => "50",
          "moneda_origen" => "USD",
          "cuenta_origen" => "userB"
        },
        %{
          "tipo" => "transferencia",
          "monto" => "50",
          "moneda_origen" => "USD",
          "moneda_destino" => "USD",
          "cuenta_origen" => "userA",
          "cuenta_destino" => "userB"
        }
      ]

      assert :ok == Validador.validar_transacciones(transacciones, tipos)
    end

    test "rechaza si la cuenta no fue dada de alta", %{tipos: tipos} do
      transacciones = [
        %{
          "tipo" => "transferencia",
          "monto" => "50",
          "moneda_origen" => "USD",
          "moneda_destino" => "USD",
          "cuenta_origen" => "userA",
          "cuenta_destino" => "userB"
        }
      ]

      assert {:error, mensaje} = Validador.validar_transacciones(transacciones, tipos)
      assert mensaje =~ "La cuenta 'userA' no fue dada de alta"
    end

    test "rechaza si la moneda no existe", %{tipos: tipos} do
      transacciones = [
        %{
          "tipo" => "alta_cuenta",
          "monto" => "100",
          "moneda_origen" => "XYZ",
          "cuenta_origen" => "userA"
        }
      ]

      assert {:error, mensaje} = Validador.validar_transacciones(transacciones, tipos)
      assert mensaje =~ "Moneda no listada en monedas.csv: XYZ"
    end
  end

  describe "cuenta_dada_de_alta/2" do
    test "retorna :ok cuando la cuenta está incluida" do
      cuentas = MapSet.new(["userA"])
      assert :ok == Validador.cuenta_dada_de_alta(cuentas, "userA")
    end

    test "retorna error cuando la cuenta no está" do
      cuentas = MapSet.new()

      assert {:error, "La cuenta 'userA' no fue dada de alta previamente"} ==
               Validador.cuenta_dada_de_alta(cuentas, "userA")
    end
  end

  describe "saldo_suficiente/4" do
    test "retorna :ok si hay saldo" do
      balances = %{"userA" => %{"USD" => 150}}
      assert :ok == Validador.saldo_suficiente(balances, "userA", "USD", 100)
    end

    test "retorna error si el saldo es insuficiente" do
      balances = %{"userA" => %{"USD" => 50}}

      assert {:error, mensaje} = Validador.saldo_suficiente(balances, "userA", "USD", 100)
      assert mensaje =~ "Saldo insuficiente en 'userA' para USD"
    end
  end

  describe "convertir/4" do
    test "convierte monto entre monedas" do
      tipos = %{"USD" => 1.0, "ARS" => 0.001}
      assert Validador.convertir(tipos, "USD", "ARS", 100) == 100_000.0
    end
  end
end
