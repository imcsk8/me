+++
title = 'Kubernetes Operators in Rust'
date = 2025-03-22T15:13:50-06:00
description = "Small tutorial for creating kubernetes operators using kube-rs"
summary = "Small tutorial for creating Kubernetes Operators in Rust"
draft = true
+++

# Creating Kubernetes Operators in Rust

TODO introduction

## Setup minikube


### Setup minikube

* Install **minikube**

```bash
$ curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
$ sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```

* Start **minikube** 

I recommend start tmux inside a `tmux` session

```bash
$ tmux new -s minkube
$ minikube start
```

* Enable **minikube** tunnel

```bash
$ minikube tunnel
```

You can exit the session by typing `CTRL-b-d`, to return to the session use `tmux a -t minkube`.


## Create the operator

* Create the project

```bash
$ cargo new --name rust-example-operator
```

* Add `kube-rs` to the `Cargo.toml` file:

```bash
    cat << EOF >> Cargo.toml
kube = { version = "0.99.0", features = ["runtime", "derive"] }
k8s-openapi = { version = "0.24.0", features = ["latest"] }
tokio = { version="1.44.1", features = [
    "macros",
    "rt-multi-thread",
] } # Macros for easy project setup and testing, multi-threaded runtime for best utilization of resources
thiserror = "2.0.12"
anyhow = "1.0.97"
log = "0.4.27"
futures-util = "0.3.31"
pretty_env_logger = "0.5.0"
EOF
```

* Create the Makefile

```
run:
	RUST_LOG=info cargo run

test:
	cargo test
```

*

* Create basic code to test the connection to **minikube**

```rust

```

* Define the API



# References
* https://kube.rs/getting-started/
* https://minikube.sigs.k8s.io/docs/start/
