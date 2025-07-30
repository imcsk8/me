+++
title = 'Cosmic Desktop'
description = "Installing COSMIC desktop on Fedora 42"
summary = "Small tutorial on how to install COSMIC desktop on Fedora distributions"
date = 2025-07-08T14:18:44-06:00
draft = false
+++

# Installing COSMIC on Fedora 42

COSMIC is a desktop environment created in Rust from the ground up. Cosmic is written for the wayland
protocol so there is no legacy code floating around like in gnome. Some of the features that caught my eye
are the modular design, customization, tiling and floating windows combination. And to be honest, Rust is my current
obsession so anything written in Rust is worth my while.


## Install COSMIC

The installation in Fedora is pretty easy, I almost skip adding a header for this because it's really only two
group install commands, kudos to the Fedora COSMIC team because these groups have all the packages needed for 
a smooth installation.

```bash
~# dnf update -y
~# dnf group install -y cosmic-desktop
~# dnf group install -y cosmic-desktop-apps
```

## Configure desktop

Most of the configuration is done with the cosmic settings "applet" but there are a bunch of directories with
configuration files under `~/.config/cosmic`. Most of the configuration options for the native COSMIC applications
have an import button which suggests that you can share your configurations in plain files. I like this focus
better than the GConf windowesque design.

## Usage Experience


### Pros

The look and feel of the whole desktop is very pleasing and it works with expected behaviours. I found the options that
I wanted to change in a very intutive way. My native language is spanish and it was a very nice surprise to see that
COSMIC recognized this setting and it got setup in spanis, also, most of the options of the native applications are in
the correct language.

### Cons

There are some stuff that still feels a little rough like: missing like image previews in file selectors, the screen capture 
application does not record video and some icons look a little pixelated in the Dock.

- Can't copy paste from vim (the mouse=a worked too well)
- If I disable hibernate the sceen does not auto lock.
- After unlocking the screen everything is unstable: missing workspaces the dock does no autohide
- I had to kill -HUP cosmic-workspaces
- terminal can't move tabs, changed to ptyxis

## Conclusion

The installation and basic configuration were very terse and the all around experience is very good. I will definetely use it
as my main desktop for the next months.


## References
* https://system76.com/cosmic
* https://fedoraproject.org/atomic-desktops/cosmic/
