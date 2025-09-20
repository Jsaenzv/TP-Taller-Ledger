# Ledger

Herramienta de línea de comandos en Elixir para:

- Listar transacciones desde un CSV.
- Calcular el balance por moneda de una cuenta, con opción de convertir a una moneda objetivo.

El ejecutable del proyecto es `ledger` (escript). El código principal está en `lib/Ledger.ex`.

**Delimitador CSV:** `;` (punto y coma).

**Archivos por defecto:**

- Transacciones: `./data/transacciones.csv`
- Monedas y tasas de cambio: `./data/monedas.csv`

---

## Uso

1) Instalar dependencias y compilar el escript:

```bash
mix deps.get
mix escript.build
```

2) Listar transacciones (usa `data/transacciones.csv` por defecto):

```bash
./ledger transacciones
```

3) Calcular balance de una cuenta (requiere `-c1`):

```bash
./ledger balance -c1=userM
```

4) Escribir la salida en un archivo en lugar de stdout con `-o=PATH`:

```bash
./ledger transacciones -o=output.csv
./ledger balance -c1=userM -o=output.csv
```

---

## Comandos y Flags

Hay dos subcomandos: `transacciones` y `balance`.

Flags admitidos (según corresponda):

- `-t=PATH`: ruta del CSV de transacciones (por defecto `./data/transacciones.csv`).
- `-o=PATH`: ruta de salida. Si se omite, imprime por stdout.
- `-c1=CUENTA`: filtra por `cuenta_origen` (en `transacciones`) o indica la cuenta para calcular `balance` (obligatorio en `balance`).
- `-c2=CUENTA`: filtra por `cuenta_destino` (solo `transacciones`).
- `-m=MONEDA`: convierte el balance completo a esta moneda (solo `balance`).

Ejemplos:

```bash
# Filtrar transacciones por cuenta origen
./ledger transacciones -c1=userA

# Filtrar por origen y destino a la vez
./ledger transacciones -c1=userA -c2=userB

# Usar un archivo de transacciones personalizado
./ledger transacciones -t=./test/data/transacciones_test.csv

# Balance de una cuenta en múltiples monedas (sin convertir)
./ledger balance -c1=userM

# Balance convertido a USDT
./ledger balance -c1=userC -m=USDT
```

---

## Formato de Archivos CSV

### `data/monedas.csv`

Encabezados esperados: `moneda;cambio`

- `moneda`: código de la moneda (ej.: `USDT`, `BTC`, `ETH`, `ARS`, ...).
- `cambio`: tasa positiva usada para convertir entre monedas. La conversión se realiza como:
  `monto_destino = tasa(moneda_origen) * monto / tasa(moneda_destino)`.

Ejemplo:

```
moneda;cambio
BTC;65000
ETH;3400
USDT;1
EUR;1.09
```

### `data/transacciones.csv`

Encabezados esperados:

```
id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo
```

Campos:

- `id`: identificador de la transacción (informativo).
- `timestamp`: entero/epoch (informativo, no participa en la validación actual).
- `moneda_origen`: moneda del monto de la operación; obligatoria y debe existir en `monedas.csv`.
- `moneda_destino`: para `transferencia` y `swap` es obligatoria y debe existir en `monedas.csv`. Para `alta_cuenta` puede estar vacía.
- `monto`: número decimal no negativo (punto como separador). No se permiten montos negativos.
- `cuenta_origen`: cuenta sobre la que se opera.
- `cuenta_destino`: solo aplica a `transferencia`.
- `tipo`: uno de `alta_cuenta`, `transferencia`, `swap`.

---

## Reglas y Validaciones

Antes de generar cualquier salida, el programa valida la consistencia del CSV de transacciones usando también `monedas.csv`.

- Tipo válido: `tipo` debe ser uno de `alta_cuenta`, `transferencia`, `swap`.
- Campos obligatorios: se verifica presencia y no vacío de los campos requeridos según el tipo de operación.
  - Siempre: `tipo`, `moneda_origen`, `monto`, `cuenta_origen`.
  - `alta_cuenta`: No requiere ningun campo adicional.
  - `transferencia`: requiere `cuenta_origen`, `cuenta_destino`, `moneda_destino`.
  - `swap`: requiere `cuenta_origen`, `moneda_destino`.
- Monedas válidas: `moneda_origen` y (si aplica) `moneda_destino` deben existir en `monedas.csv`.
- Altas previas: para `transferencia` se exige que tanto `cuenta_origen` como `cuenta_destino` hayan sido dadas de alta previamente (mediante una transacción `alta_cuenta`). Para `swap`, `cuenta_origen` también debe existir previamente.
- Suficiencia de saldo: en `transferencia` y `swap` se verifica que la cuenta origen tenga saldo suficiente en `moneda_origen`.
- Monto: debe poder parsearse a número y ser `>= 0`.

Si alguna validación falla, se detiene el procesamiento y se devuelve un error con el formato:

```
Error en la línea N, razon: <descripción>
```

La línea `N` refiere a la posición de la fila dentro del conjunto de transacciones leídas (excluyendo el encabezado).

---

## Semántica de las Operaciones

- `alta_cuenta`:
  - Marca la cuenta como dada de alta y acredita `monto` en `moneda_origen`.
- `transferencia`:
  - Debita `monto` de `cuenta_origen` en `moneda_origen`.
  - Acredita el monto convertido en `cuenta_destino` en `moneda_destino`.
- `swap`:
  - Dentro de la misma `cuenta_origen`, debita `monto` en `moneda_origen` y acredita el monto convertido en `moneda_destino`.

Estas reglas se usan para validar y también para calcular balances.

---

## Salidas

### `transacciones`

- Devuelve filas en el mismo orden y con el mismo formato del CSV de entrada (sin el encabezado), aplicando filtros de `-c1` y/o `-c2` si se especifican.
- Si se proporciona `-o=PATH`, se escribe la salida en el archivo indicado; si no, se imprime por stdout.

### `balance`

- Requiere `-c1=CUENTA`.
- Calcula el balance de la cuenta por moneda, considerando:
  - Altas de cuenta e ingresos/egresos por transferencias.
  - Swaps dentro de la misma cuenta.
- Si se especifica `-m=MONEDA`, convierte el balance total a esa moneda y lo emite como un único par `MONEDA;MONTO`.
- La salida se ordena alfabéticamente por moneda y los montos se muestran con 6 decimales.

---

## Ejemplos Reales (basados en tests)

```bash
# Usando el CSV de ejemplo de test
./ledger transacciones -t=./test/data/transacciones_test.csv

# Filtrar transacciones de userA
./ledger transacciones -t=./test/data/transacciones_test.csv -c1=userA

# Balance de userM
./ledger balance -t=./test/data/transacciones_test.csv -c1=userM

# Balance de userC convertido a USDT
./ledger balance -t=./test/data/transacciones_test.csv -c1=userC -m=USDT
```

---

## Desarrollo

- Requisitos: Elixir `~> 1.18`.
- Dependencias: `:csv` (`~> 2.4`).
- Compilar escript: `mix escript.build` genera el ejecutable `./ledger`.
- Ejecutar tests: `mix test`.

---

## Notas

- El proyecto asume separador `;` en todos los CSV.
- Los encabezados pueden o no estar presentes en los archivos CSV. El lector interno maneja ambos casos.
- Los números decimales usan `.` como separador.
- Las tasas de cambio deben ser positivas para que la conversión tenga sentido.

