+++
title = 'Tutorial de Rocket'
date = 2024-12-03T23:34:12-06:00
draft = false
+++

# Tutorial de Rocket

## Introducción

## Instalación de dependencias

```bash
$ sudo dnf install -y libpq rust cargo make
$ cargo install diesel_cli diesel_cli_ext
```


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

## Creación de rutas

Editamos main.rs para probar una ruta:

* Agregamos dependencias de rocket

```rust
extern crate rocket;
use rocket::fs::FileServer;
use rocket::response::Debug;
use rocket::{launch, routes};
use rocket_dyn_templates::Template;
//https://rocket.rs/guide/v0.5/requests/
```

## Base de datos

```bash
```
## Request Guards

```bash
```
## Pruebas


```bash
```
