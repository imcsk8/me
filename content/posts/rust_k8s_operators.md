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
EOF
```

* Create basic code to test the connection

* Define the API



# References
* https://kube.rs/getting-started/
* https://minikube.sigs.k8s.io/docs/start/
