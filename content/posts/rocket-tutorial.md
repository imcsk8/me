+++
title = 'Tutorial de Rocket'
date = 2024-12-03T23:34:12-06:00
draft = false
summary = "Tutorial rápido para aprender a usar Rocket, un framework para crear aplicaciones web en Rust"
+++

# Tutorial de Rocket

## Introducción

## Instalación de dependencias

```bash
$ sudo dnf install -y libpq rust cargo make
$ cargo install diesel_cli diesel_cli_ext
```

* https://github.com/imcsk8/examples

* https://github.com/SotolitoLabs/TourMasters

## Creación de proyecto

```bash
```

```bash
$ cargo new posadev
$ cd posadev
$ cargo run
```

## Creación de Makefile

El `make` nos sirve para llevar el control de los elementos que hemos compilado y
para tener un flujo de trabajo para la compilación de la aplicación.

```bash
# Posadev

run:
	cargo run

clean:
	cargo clean
```

Probamos ejecución

```bash
$ make clean
$ make run
```

## Adición de dependencias


```bash
$ cargo add diesel rocket dotenvy serde uuid jsonwebtoken lazy_static
```

Agregamos las siguientes dependecias a `Cargo.toml`


```bash
[dependencies.rocket_dyn_templates]
version = "0.2.0"
features = ["handlebars"]

[dependencies.rocket_sync_db_pools]
version = "0.1.0"
features = ["diesel_postgres_pool", "postgres_pool"]
```

## Creación de rutas

Editamos main.rs para probar una ruta:

* Agregamos dependencias de rocket

```rust
extern crate rocket;
use rocket::fs::FileServer;
use rocket::response::Debug;
use rocket::{launch, routes};
use rocket_dyn_templates::Template;
use rocket::get;
//https://rocket.rs/guide/v0.5/requests/
```

* Creamos primera ruta:

La macro `#[launch]` nos genera el código necesario para la ejecución de la
aplicación.
Aquí vemos una de las características mas importantes de Rocket: la generación de código.
Las macros de Rust nos permiten ahorrarnos mucho código __boilerplate__ y condensarlo
en "decoradores" que le agregan código a las funciones en base a su contenido.

La macro `routes!` genera el códig necesario para la creación de rutas.

```rust
#[launch]
fn rocket() -> _ {
    rocket::build()
        .mount("/", routes![hello])
}
```

La función `build()` nos crea el servidor y la función `mount(...)` agrega rutas para
ser servidas hacia los clientes.

### Agregamos función `hello`

En `main.rs`

```rust
/// Just says hi
#[get("/")]
pub async fn hello() -> String {
	String::from("Hola posadev!")
}
```

## Base de datos

### Migraciones

Rust cuenta con una biblioteca (de ahora en adelante les diremos *crates* o *huacales*) llamada *diesel* que nos permite interactuar con bases de datos.
*Diesel* funciona de manera similar a los ORMs de frameworks como: *Django*, *Rails* o *flask*.

En este caso usamos la aplicación de línea de comando: `diesel` para insertar el
esquema SQL a la base de datos.
Esto puede parecer poco ortodoxo ya que tradicionalmente los ORMs generan el SQL en base
a las estructuras de datos de la aplicación, pero desde el punto de vista de bases de datos
es mejor escribir nosotros el SQL y usar las herramientas de *Diesel* para generar las
estructuras de datos de la aplicación.
Esto nos permite controlar la creación de tablas, índices, __triggers__ y demás elementos
de la base datos desde la perspectiva de *PostgreSQL* para tenerlos mas optimizados.

### Preparamos ambiente para uso de diesel_cli

En la raíz del proyecto, agregamos `~/.cargo/bin/` a nuestra variable de
ambiente `PATH` para poder ejecutar las herramientas de __CLI__ de
*Diesel*:

```bash
$ export PATH=$PATH:~/.cargo/bin
```

Creamos el directorio donde se van a almacenar nuestras migraciones

```bash
$ mkdir migrations
```

#### Creamos migraciones de nuestras tablas.

* **Eventos**

```bash
$ diesel migration create events
Creating migrations/2024-12-05-234041_events/up.sql
Creating migrations/2024-12-05-234041_events/down.sql
```

Este comando nos crea el directorio a la migración correspondiente y dos archivos:
`up.sql` para crear nuestras tablas y demaś elementos y `down.sql` que revierte lo que
creamos en `up.sql`. En estos archivos se escribe el código *SQL* tal y como se le
escribiría al motor de base de datos.

Agregamos la definición de la tabla `events` a nuestro archivo `up.sql`:


```sql
-- Events
CREATE TABLE IF NOT EXISTS Event (
    Id UUID,
    Name TEXT,
    Venue TEXT,
    Address TEXT,
    ContactName VARCHAR(255),
    Starts_at TIMESTAMP NOT NULL DEFAULT NOW(),
    Ends_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY(Id)
)
```

### Base de datos

Para evitar configurar localmente nuestra base de datos podemos usar un contenedor
de *PostgreSQL*, agregamos su ejecución a nuestro *Makefile*:

Agregamos los targets

```bash

.env:
	echo "DATABASE_URL=postgres://postgres:prueba123@127.0.0.1:9432/postgres" > .env

./www/static:
	mkdir -p www/static

./data:
	mkdir data

dirs: www/static data .env

db: data
	podman run -d --replace --name=posadev_pg                    \
		-e POSTGRES_PASSWORD=prueba123                           \
		-v ./data:/var/lib/postgresql/data:U,Z                   \
		-p 127.0.0.1:9432:5432 ghcr.io/enterprisedb/postgresql:16

```

Incluímos también los targets para crear los directorios de datos, estático y el archivo
`.env` que contiene las credenciales del usuario que se conecta a la base de datos.

El `Makefile` completo es de la siguiente manera:

```bash
# Posadev

.env:
	echo "DATABASE_URL=postgres://postgres:prueba123@127.0.0.1:9432/postgres" > .env

./www/static:
	mkdir -p www/static

./data:
	mkdir data

dirs: www/static data .env

db: data
	podman run -d --replace --name=posadev_pg                    \
		-e POSTGRES_PASSWORD=prueba123                           \
		-v ./data:/var/lib/postgresql/data:U,Z                   \
		-p 127.0.0.1:9432:5432 ghcr.io/enterprisedb/postgresql:16

run: dirs db
	cargo run

clean:
	cargo clean
```

* Levantamos el servidor de base de datos:

```bash
$ make db
```

* Nos conectamos para confirmar que funciona correctamente:

```bash
$ source .env
$ psql $DATABASE_URL
psql (16.3, servidor 16.4)
Digite «help» para obtener ayuda.

postgres=# \q
```

* Ejecutamos las migraciones:


```bash
$ diesel migration run
```

* Confirmamos que la migración se ejecutó correctamente:

```bash
$ source .env
$ psql $DATABASE_URL
postgres=# \d
                  Listado de relaciones
 Esquema |           Nombre           | Tipo  |  Dueño
---------+----------------------------+-------+----------
 public  | __diesel_schema_migrations | tabla | postgres
 public  | event                      | tabla | postgres
(2 filas)

postgres=# \d event
                               Tabla «public.event»
   Columna   |            Tipo             | Ordenamiento | Nulable  | Por omisión
-------------+-----------------------------+--------------+----------+-------------
 id          | uuid                        |              | not null |
 name        | text                        |              |          |
 venue       | text                        |              |          |
 address     | text                        |              |          |
 contactname | character varying(255)      |              |          |
 starts_at   | timestamp without time zone |              | not null | now()
 ends_at     | timestamp without time zone |              | not null | now()
Índices:
    "event_pkey" PRIMARY KEY, btree (id)
```

Diesel necesita un archvivo llamado `schemas.rs` que contiene referencias para traducir de *Rust* a *PostgreSQL*. Lo generamos con el comando `diesel print-schema`:

```bash
$ diesel print-schema > src/schema.rs
```

Finalmente generamos el archivo `src/models.rs` que es el que tiene las estructuras que usamos
dentro de nuestros módulos:

```bash
diesel_ext -t -s src/schema.rs -m \
  -I "crate::schema::*"           \
  -I "rocket::serde::{ Deserialize, Serialize }"       \
  -d "Clone, Debug, Identifiable, Queryable, QueryableByName, Insertable, Serialize, Deserialize" > src/models.rs
```

Para realizar todo este merequetengue creamos un archivo llamado `generate_models.sh` en la raíz
del proyecto:

```bash
#!/bin/bash

DERIVE_FLAGS="Clone, Debug, Identifiable, Queryable, QueryableByName, Insertable, Serialize, Deserialize"

echo "Running diesel migrations"
diesel migration run

echo "Gettting schema from database"
diesel print-schema > src/schema.rs

echo "Generating models"
diesel_ext -t -s src/schema.rs -m \
  -I "crate::schema::*"           \
  -I "rocket::serde::{ Deserialize, Serialize }"       \
  -d "${DERIVE_FLAGS}" > src/models.rs
```

Este script se debe ejecutar cada vez que ejecutamos migraciones.

Creamos el módulo `src/db.rs`

```bash
use rocket_sync_db_pools::database;
use rocket_sync_db_pools::diesel;

#[database("postgres")]
pub struct EventDB(diesel::PgConnection);
```

* Configuramos la base de datos en `Rocket.toml`

```bash
# TEST VALUES, set the proper values here
[global.databases.postgres]
url = "postgres://postgres:prueba123@127.0.0.1:9432/postgres"
timeout = 5
pool_size = 2

```


## Creamos los endpoints para agregar y consultar eventos.

### Creación de eventos:

```bash
```

```bash
```

## Request Guards

Se implementa el trait `FromRequest` el cual es ejecutado por `rocket`.
Si este trait está implementado para una argumento de una función, se
ejecuta la función `from_request`.

Revisar `claims.rs`

```bash
//Rocket request guard
#[rocket::async_trait]
impl<'r> FromRequest<'r> for Claims {
    type Error = AuthenticationError;
    async fn from_request(request: &'r rocket::Request<'_>) -> Outcome<Self, Self::Error> {
        match request.headers().get_one(AUTHORIZATION) {
            Some(v) => match Claims::from_authorization(v) {
                Ok(c) => Outcome::Success(c),
                Err(e) => Outcome::Error((Status::Forbidden, e)),
            },
            None => Outcome::Error((Status::Forbidden, AuthenticationError::Missing)),
        }
    }
}
```
## Pruebas


```bash
```
