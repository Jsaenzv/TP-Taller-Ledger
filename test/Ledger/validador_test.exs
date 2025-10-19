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
end
