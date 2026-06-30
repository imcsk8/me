+++
title = 'Security Sucks: Gopass on Multiple Machines'
date = 2026-06-27T08:31:19-06:00
draft = false
description = "Step-by-step guide to implement Gopass on multiple boxes"
summary = "Part of my Security Sucks series: Step by step guide to implement Gopass on multiple boxes"
+++

# Gopass on Multiple Boxes

Welcome to another installment of my _Security Sucks_ series: Security is not fun,
it's uncomfortable, it's complicated, but it's... well... secure.

Today, we'll set up a Gopass environment for personal passwords across multiple
machines from scratch.


## Install Gopass

```bash
# dnf install -y pass python3-pass-import gopass gnupg2
```

## Setup Environment


### Configure GPG Key

* Use Elliptic Curve key, select `9` which is a nice default.

```bash
me@box ~$ gpg --full-generate-key

gpg (GnuPG) 2.4.9; Copyright (C) 2025 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Por favor seleccione tipo de clave deseado:
   (1) RSA and RSA
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (9) ECC (sign and encrypt) *default*
  (10) ECC (sólo firmar)
  (14) Existing key from card
Su elección: 9

```

* Select `(1) Curve 25519`, this is a modern standard that uses 
`Ed25519` for signing and `X25519` for encryption.

```
Please select which elliptic curve you want:
   (1) Curve 25519 *default*
   (4) NIST P-384
   (6) Brainpool P-256
Your selection? 1
```

* Set `0` to avoid surprise expirations, just remember to manage your
keys responsibly.

```
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 
```

* Set the key information:

```
GnuPG needs to construct a user ID to identify your key.

Real name: Iván Chavero
Email address: ichavero_@_example.com.mx
Comment: Gopass GPG Key
You are using the 'iso-8859-1' character set.
You selected this USER-ID:
    "Iván Chavero (Gopass GPG Key) <ichavero_@_example.com.mx>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? 
```

Type your passphrase in the prompt to finish the key creation.

### Configure GPG agent cache

* Edit the `~/.gnupg/gpg-agent.conf` file.

```
# Remember pin for 1 hour after last usage
default-cache-ttl 3600

# Remember pin for 8 hours max
max-cache-ttl 28800

# For using SSH with your hardware key
default-cache-ttl-ssh 3600
```

* Restart the GPG agent.

```bash
me@box ~$ gpgconf --kill gpg-agent
```

### Initialize the remote store

```bash
me@remote ~$ ssh remote
me@remote ~$ mkdir gopass
me@remote ~$ cd gopass
me@remote ~$ git init bare
```


## Configure Gopass

```bash
me@box ~$ gopass setup

   __     _    _ _      _ _   ___   ___
 /'_ '\ /'_'\ ( '_'\  /'_' )/',__)/',__)
( (_) |( (_) )| (_) )( (_| |\__, \\__, \
'\__  |'\___/'| ,__/''\__,_)(____/(____/
( )_) |       | |
 \___/'       (_)

🌟 Welcome to gopass!
🌟 Initializing a new password store ...
🔐 Using crypto backend: gpgcli
💾 Using storage backend: gitfs
🌟 Configuring your password store ...
🎮 Please select a private key for encrypting secrets:
[0] gpg - 0x001DFF4314F3F2E3 - Iván Chavero (Gopass GPG Key) <ichavero@example.com.mx>
Please enter the number of a key (0-1, [q]uit) (q to abort) [0]: 
❓ Do you want to add a git remote? [y/N/q]: y
Configuring the git remote ...
Please enter the git remote for your shared store []: remote:gopass
```

### Create a secret

```bash
me@box ~$ gopass create
🌟 Welcome to the secret creation wizard (gopass create)!
🧪 Hint: Use 'gopass edit -c' for more control!
[ 0] Website login
[ 1] PIN Code (numerical)

Please select the type of secret you would like to create (q to abort) [0]: 0

```

### Import secret from browsers

Storing passwords in the web browser is a crappy security practice, as well as a
huge inconvenience when you have multiple machines and need passwords to be in
sync.

* Open Firefox and navigate to about:logins.

* Click the three dots (menu) in the top right corner and select Export Logins...

* Save the resulting .csv file.

* Use the `pass-import` extension created for the original `pass` command to import the credentials.

```bash
me@box ~$ PASSWORD_STORE_DIR=~/.local/share/gopass/stores/root pass import firefox logins.csv
```

* Verify that the passwords were imported correctly.

```bash
me@box ~$ gopass list
gopass
├── 192.168.1.1/
│   ├── admin
│   ├── hotelcdm
│   ├── notitle
...
```

### Common usage

At first, I thought `gopass` was going to add some overhead to my day-to-day workflow.
I was willing to accept it because _security sucks_, but it was a nice surprise that it wasn't
the case.
Turns out, `gopass` is a very easy-to-use tool!

* List passwords.

```bash
me@box ~$ gopass ls
```

* Copy an existing password to the clipboard.

```bash
me@box ~$ gopass -c ichavero_@_gmail.com
⚠ Entry "example@gmail.com" not found. Starting search...
[ 0] accounts.google.com/example@gmail.com
...
Found secrets - Please select an entry (q to abort) [0]: 0

# This will take you to the GPG password Screen depending on your cache settings

accounts.google.com/example@gmail.com
✔ Copied accounts.google.com/example@gmail.com to clipboard. Will clear in 45 seconds.

```

* Create a new secret.


```bash
me@box ~$ gopass create
🌟 Welcome to the secret creation wizard (gopass create)!
🧪 Hint: Use 'gopass edit -c' for more control!
[ 0] Website login
[ 1] PIN Code (numerical)

Please select the type of secret you would like to create (q to abort) [0]:
```

### Remote synchronization

The whole point of using `gitfs` with `gopass` is to keep passwords in sync.
To do this, you need to have `gopass`, `gnupg` tooling and your GPG key installed on the remote
machine.


* List your GPG keys.
Find your key ID in the `sec` field: `rsa4096/63C691E1159BE48C`. It's the string
that comes after the slash (/). In this case: **63C691E1159BE48C**.


```bash
me@box ~$ gpg --list-secret-keys --keyid-format=long
sec   rsa4096/63C691E1159BE48C 2024-02-29 [SC]
      EF3972FF7CFC16394676A0F763C69DEC1791E48C
uid                 [ultimate] Iván Chavero <ichavero@example.com.mx>
ssb   rsa4096/AE60575D0176D360 2024-02-29 [E]
...
```

* Export your `gopass` public key.

```bash
me@box ~$ gpg --armor --export 63C691E1159BE48C > gopass_public_key.asc
```

* Export your private key.

```bash
me@box ~$ gpg --armor --export-secret-keys 63C691E1159BE48C > gopass_private_key.asc
```

* Copy keys to the remote machine.

```bash
me@box ~$ scp gopass* remote:gopass/.
```

* Import public key in your remote machine.

```bash
me@remote ~$ gpg --import gopass_public_key.asc
...
```

* Import the private key.

```bash
me@remote ~$ gpg --import gopass_private_key.asc
...
...
```

* Trust the new key in the remote machine. From the menu select `5` (I trust ultimately),
type `y` to confirm and then `quit` to exit the program.


```bash
me@remote ~$ gpg --edit-key 63C691E1159BE48C
Secret key is available.

...

gpg> trust
sec  ed25519/63C691E1159BE48C
     created: 2026-06-27  expires: never       usage: SC  
     trust: unknown       validity: unknown

...

Please decide how far you trust this user to correctly verify other users' keys
(by looking at passports, checking fingerprints from different sources, etc.)

  1 = I don't know or won't say
  2 = I do NOT trust
  3 = I trust marginally
  4 = I trust fully
  5 = I trust ultimately
  m = back to the main menu

Your decision? 5
Do you really want to set this key to ultimate trust? (y/N) y
```

* Configure `gopass` local root store. This is needed before using a remote store.

```bash
me@box ~$ gopass setup

   __     _    _ _      _ _   ___   ___
 /'_ '\ /'_'\ ( '_'\  /'_' )/',__)/',__)
( (_) |( (_) )| (_) )( (_| |\__, \\__, \
'\__  |'\___/'| ,__/''\__,_)(____/(____/
( )_) |       | |
 \___/'       (_)

🌟 Welcome to gopass!
🌟 Initializing a new password store ...
🔐 Using crypto backend: gpgcli
💾 Using storage backend: gitfs
🌟 Configuring your password store ...
❓ Do you want to add a git remote? [y/N/q]: n

```

* Clone the remote store.

```bash
me@box ~$ gopass setup
gopass clone soho1:gopass personal
...
```

That's it! Now you can share your passwords in a secure, synchronized way. I know it's a
hassle, but I assure you that the future you will thank you for your time. Maybe he'll sleep
better at night (or day?) than your current self.

No, it's not easy. If someone tells you this is easy, they're lying or trying to sell you their shit, because
as you should know: _Security Sucks_. But it beats the hell out of being naked on the information superhighway ;).


## References

* https://github.com/gopasspw/gopass
* https://woile.github.io/gopass-cheat-sheet/
* https://www.gnupg.org/gph/en/manual/c14.html
