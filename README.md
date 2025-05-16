# Introduction

The `nfh` helps you generate lists of files from your Nix File Hierarchy.

Have you ever dreamed about auto imports? About disabling some of them? Then
`nfh` is for you!

# How does it work?

At the first call, `nfh` generates an attribute set representing the structure
of the specified directory. Only `nix` files are included. Any `default.nix`
file is assigned the attribute name `self`.

```fish
> tree modules/
modules/
├── auth.nix
├── boot.nix
├── desktop
│   ├── firefox.nix
│   ├── foot.nix
│   ├── kde
│   │   ├── default.nix
│   │   └── krunner.nix
│   └── sway
│       ├── default.nix
│       ├── swayidle.nix
│       └── systemd-integration.nix
└── networking
    ├── iwd.nix
    ├── networkd.nix
    ├── openssh.nix
    └── tor.nix
```

```nix
nix-repl> fileSet = inputs.nfh ./modules

nix-repl> :p lib.filterAttrsRecursive (name: _: name != "__functor") fileSet
{
  auth = modules/auth.nix;
  boot = modules/boot.nix;
  desktop = {
    firefox = modules/desktop/firefox.nix;
    foot = modules/desktop/foot.nix;
    kde = {
      krunner = modules/desktop/kde/krunner.nix;
      self = modules/desktop/kde/default.nix;
    };
    sway = {
      self = modules/desktop/sway/default.nix;
      swayidle = modules/desktop/sway/swayidle.nix;
      systemd-integration = modules/desktop/sway/systemd-integration.nix;
    };
  };
  networking = {
    iwd = modules/networking/iwd.nix;
    networkd = modules/networking/networkd.nix;
    openssh = modules/networking/openssh.nix;
    tor = modules/networking/tor.nix;
  };
}
```

This also recursively adds a functor to each attribute set, which allows you
easily convert a specific part of your file hierarchy into a list of files:

#### list of all files

```nix
nix-repl> fileSet { }                                                                                                                                             
[
  modules/auth.nix
  modules/boot.nix
  modules/desktop/firefox.nix
  modules/desktop/foot.nix
  modules/desktop/kde/krunner.nix
  modules/desktop/kde/default.nix
  modules/desktop/sway/default.nix
  modules/desktop/sway/swayidle.nix
  modules/desktop/sway/systemd-integration.nix
  modules/networking/iwd.nix
  modules/networking/networkd.nix
  modules/networking/openssh.nix
  modules/networking/tor.nix
]
```

#### filter some files/dirs

```nix
nix-repl> fileSet { 
            auth = false;
            desktop.sway = false;
            networking.tor = false;
          }
[
  modules/boot.nix
  modules/desktop/firefox.nix
  modules/desktop/foot.nix
  modules/desktop/kde/krunner.nix
  modules/desktop/kde/default.nix
  modules/networking/iwd.nix
  modules/networking/networkd.nix
  modules/networking/openssh.nix
]
```

#### list of all files from a specific directory

```nix
nix-repl> fileSet.desktop.sway { }
[
  modules/desktop/sway/default.nix
  modules/desktop/sway/swayidle.nix
  modules/desktop/sway/systemd-integration.nix
]
```

#### use special attribute `_reverseRecursive` to filter out all files by default

```nix
nix-repl> fileSet {
            _reverseRecursive = true;
            networking = false; # since reversed once use `false` to enable import
            desktop = {
              _reverseRecursive = true;
              firefox = false; # since reversed twice use `false` to disable import
              sway = false; # since reversed twice use `false` to disable import
            };
          }
[
  modules/desktop/foot.nix
  modules/desktop/kde/krunner.nix
  modules/desktop/kde/default.nix
  modules/networking/iwd.nix
  modules/networking/networkd.nix
  modules/networking/openssh.nix
  modules/networking/tor.nix
]
```

#### filter out all but one file using `_reverse`

```nix
nix-repl> fileSet { desktop.sway = { _reverse = true; swayidle = false; }; }                                                                                      
[
  modules/auth.nix
  modules/boot.nix
  modules/desktop/firefox.nix
  modules/desktop/foot.nix
  modules/desktop/kde/krunner.nix
  modules/desktop/kde/default.nix
  modules/desktop/sway/swayidle.nix
  modules/networking/iwd.nix
  modules/networking/networkd.nix
  modules/networking/openssh.nix
  modules/networking/tor.nix
]
```

# Getting Started

Start with the template and follow the steps described in its
[readme](/templates/nixos-configuration/README.md).

```fish
nix --extra-experimental-features 'flakes nix-command' flake init -t github:name-snrl/nfh
```

Also check out the
[author's configuration](https://github.com/name-snrl/nixos-configuration).
