# Ledger

Herramienta de línea de comandos en Elixir para:

- Administrar usuarios, monedas, cuentas y transacciones persistidas en PostgreSQL.
- Registrar operaciones (altas de cuentas, transferencias, swaps y reversas) de manera consistente.
- Consultar balances por usuario y moneda, así como el detalle de transacciones.

El ejecutable del proyecto es `ledger` (escript). La lógica del CLI se encuentra en `lib/Ledger/CLI.ex`.

**Base de datos por defecto:** `ledger` (dev) y `ledger_test` (test) en `localhost:5432`.

**Credenciales por defecto:** usuario `postgres`, password `postgres`.

---

## Requisitos Previos

1) Tener PostgreSQL en ejecución y accesible con las credenciales configuradas.
2) Ajustar `config/dev.exs` y `config/test.exs` en caso de usar valores distintos a los provistos.

---

## Uso

1) Instalar dependencias, preparar la base de datos y compilar el escript:

```bash
mix deps.get
mix ecto.setup  # crea la base de datos y ejecuta todas las migraciones
mix escript.build
```

2) Ejecutar comandos del CLI:

```bash
./ledger <comando> [flags]
```

---

## Comandos y Flags

Los flags se pasan como `-clave=valor`. Atajos disponibles:

- `-n`: nombre.
- `-b`: fecha de nacimiento (`YYYY-MM-DD`).
- `-u`: id de usuario.
- `-id`: id genérico (moneda o transacción).
- `-m`: id de moneda.
- `-mo`: id de moneda origen.
- `-md`: id de moneda destino.
- `-a`: monto.
- `-c1`: id de usuario origen para consultas.
- `-c2`: id de usuario destino para consultas.
- `-o`: id de usuario origen en transferencias.
- `-d`: id de usuario destino en transferencias.
- `-p`: precio en dólares.

### Consultas

```bash
./ledger transacciones [-c1=ID_USUARIO] [-c2=ID_USUARIO]
./ledger balance -c1=ID_USUARIO [-m=ID_MONEDA]
```

- `transacciones`: lista las transacciones registradas. Sin filtros devuelve todas; con `-c1` y/o `-c2` filtra por cuentas origen/destino.
- `balance`: muestra las cuentas de un usuario. Con `-m` restringe la salida a una moneda específica.

### Usuarios

```bash
./ledger crear_usuario -n=NOMBRE -b=AAAA-MM-DD
./ledger editar_usuario -u=ID_USUARIO [-n=NOMBRE] [-b=AAAA-MM-DD]
./ledger eliminar_usuario -u=ID_USUARIO
./ledger ver_usuario -u=ID_USUARIO
```

### Monedas

```bash
./ledger crear_moneda -n=CODIGO -p=PRECIO
./ledger editar_moneda -id=ID_MONEDA -p=PRECIO
./ledger "borrar moneda" -id=ID_MONEDA
./ledger ver_moneda -id=ID_MONEDA
```

- `crear_moneda`: registra una nueva moneda (3 o 4 letras mayúsculas) con su precio spot en dólares.
- `editar_moneda`: actualiza el precio. El nombre no puede modificarse una vez creada.
- `borrar_moneda`: elimina la moneda indicada.

### Cuentas y Transacciones

```bash
./ledger alta_cuenta -u=ID_USUARIO -m=ID_MONEDA -a=MONTO
./ledger realizar_transferencia -o=ID_ORIGEN -d=ID_DESTINO -m=ID_MONEDA -a=MONTO
./ledger realizar_swap -u=ID_USUARIO -mo=ID_MONEDA_ORIGEN -md=ID_MONEDA_DESTINO -a=MONTO
./ledger deshacer_transaccion -id=ID_TRANSACCION
./ledger ver_transaccion -id=ID_TRANSACCION
```

- `alta_cuenta`: crea una cuenta para el usuario y acredita el monto inicial.
- `realizar_transferencia`: traslada fondos entre usuarios en la misma moneda; debita del origen y acredita al destino.
- `realizar_swap`: convierte saldo entre dos monedas de un mismo usuario (ambas cuentas deben existir).
- `deshacer_transaccion`: genera una transacción inversa de la indicada, siempre que sea la última en todas las cuentas involucradas.
- `ver_transaccion`: imprime el detalle de una transacción puntual.

---

## Reglas y Validaciones

Las operaciones se validan mediante changesets de Ecto antes de persistir cambios:

- **Usuarios:** `nombre` obligatorio y único; `fecha_nacimiento` obligatoria, con edad mínima de 18 años.
- **Monedas:** `nombre` requerido, entre 3 y 4 caracteres en mayúsculas, único y no modificable después de crearse; `precio_en_dolares` obligatorio.
- **Cuentas:** combinación única (`usuario_id`, `moneda_id`); referencias válidas a usuario y moneda; el balance se actualiza automáticamente al registrar transacciones.
- **Transacciones:** `monto > 0`, `tipo` válido (`alta_cuenta`, `transferencia`, `swap`, `reversa`); asociaciones a cuentas y monedas existentes; las transferencias exigen cuenta/moneda destino; los swaps operan sobre cuentas propias. Todas las operaciones se ejecutan dentro de una transacción de base de datos.
- **Reversas:** solo se puede deshacer la última transacción registrada en cada cuenta involucrada; si la validación falla la operación se revierte.

Los errores se devuelven con el motivo correspondiente y ningún cambio queda aplicado si la validación falla.

---

## Desarrollo y Tests

- Al iniciar la aplicación (`iex -S mix`) se levanta `Ledger.Repo` bajo supervisión.
- Para preparar y ejecutar la suite de pruebas:

```bash
MIX_ENV=test mix ecto.setup
mix test
```

- Las configuraciones de base de datos por entorno están en `config/dev.exs` y `config/test.exs`.

---
