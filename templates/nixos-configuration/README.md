# Introduction

Generated file structure:

```bash
│   # module based on flake-parts, by default it imports
│   # all modules from ./modules/flake-parts
├── flake.nix
│   # directory whose contents will be converted to attribute set of module paths
└── modules
    ├── flake-parts
    │   │   # default module generates `nixosConfigurations`
    │   │   # and contains an example overlay
    │   ├── default.nix
    │   │   # this one makes it easier to work with `system`
    │   └── perSystem.nix
    └── nixos
        ├── configurations
        │   │   # this directory name will be converted to a
        │   │   # value for `networking.hostName`
        │   └── host-name
        │       │   # these files are the entry point for each NixOS configuration,
        │       │   # they will all be imported for a given host, these files are
        │       │   # expected to contain host-specific configuration parameters
        │       └── default.nix
        └── profiles
            │   # some useful default settings for beginners, you free to remove them
            ├── aliases.nix
            └── nix.nix
```

A few words about [flake-parts](https://github.com/hercules-ci/flake-parts).

This library allows you to define flake outputs not only in the root flake file,
but also to create modules to do so. This makes your system even more modular.
It also take care of `system` stuff. More information can be found
[here](https://flake.parts/). I've added some simple usage examples see
`modules/flake-parts`.

Now let's create your first configuration or migrate an existing one to **nfh**!

# You already have a configuration

Let's start with one configuration.

- Move the modules specific to this NixOS configuration to the
  `modules/nixos/configurations/host-name` directory. Now rename this directory
  to the desired hostname. The directory name will be used to define the
  `networking.hostName` option, so you should remove this option from your
  configuration.
- If `hardware-configuration.nix` was created a long time ago and does not
  contain the `nixpkgs.hostPlatform` option, I would recommend recreating it
  with the command:
  ```bash
  nixos-generate-config --show-hardware-config > modules/nixos/configurations/host-name/hw-configuration.nix
  ```
- Remove all manual imports from modules, files in the host directory will be
  imported automatically. About the management of shared modules below.
- Move all modules and profiles shared by your configurations (`NixOS`,
  `Home Manager`, etc) to the `modules/` directory.
- The following expression will allow you to manage module imports in your
  configurations based on the file structure:
  ```nix
  imports = importsFromAttrs {
    importByDefault = true;
    modules = inputs.self.moduleTree.nixos;
    # or use `inputs.self.moduleTree.home-manager` for home-manager modules
    imports = {
      configurations = false;
      #profiles.nix = false;
      #profiles.aliases = false;
    };
  };
  ```
  As you may have noticed a similar expression is already present in the
  `modules/nixos/configurations/host-name/default.nix` file, you can use it for
  your first configuration.

Done! Try to switch or build your configuration:

```bash
nixos-rebuild switch --use-remote-sudo --flake
```

```bash
nix build --no-link .#nixosConfigurations.<hostName>.config.system.build.toplevel 
```

Move the rest of the configurations, creating directories for each by analogy.

# This is your first NixOS configuration

Some must-have resources you should know about:

- [NixOS Manual](https://nixos.org/manual/nixos/unstable/), contains many
  manuals on how to configure various services, as well as the standard
  installation manual from a minimal image, which we will use, with a few
  modifications.
- [Nixpkgs packages search](https://search.nixos.org/packages), or use
  `nix search nixpkgs firefox` command.
- [Nixpkgs options search](https://search.nixos.org/options), you can also find
  them in man pages - `man configuration.nix`.

## Preparations

Instead of making configuration changes in an unfamiliar environment after
booting into a live CD, I suggest doing it right now, in a familiar environment.
So, let's write your first NixOS module, which will contain a set of key
packages and services:

- Create a new nix file in the `modules/nixos/profiles` directory.
- See the
  [configuration section](https://nixos.org/manual/nixos/unstable/#ch-configuration)
  in the NixOS manual to enable your favorite desktop environment.
- You can search for packages and options using a search engine.

If you are not yet confident enough in your nix language skills, you can use the
example below:

```nix
{ pkgs, ... }: {
  # Enable Plasma 6 with SDDM
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin";
    };
  };
  programs = {
    htop.enable = true;
    git = {
      enable = true;
      config = {
        init.defaultBranch = "master";
        user = {
          name = "name";
          email = "name@example.com";
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    file
    tree
    wget
  ];
}
```

This module will enable KDE Plasma 6 with SDDM and install programs such as
`git` and `htop`, note that you must make changes to the git configuration (name
and email). It will also install a small set of packages.

Finally defint the host name by renaming the
`modules/nixos/configurations/host-name` directory, as mentioned above, the
`networking.hostName` option will be set automatically when
`nixosConfigurations` is generated.

## First installation

First of all you need to
[get](https://nixos.org/manual/nixos/unstable/#sec-obtaining) and boot from a
live CD, it doesn't matter which one you choose, it won't affect the end result.
Installation will be done by executing commands through the command line
interface, whether it is a graphical terminal emulator or TTY in a minimal
image.

The installation will take place in 3 phases:

- [Networking](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-networking).
- [Partitioning and formatting](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-partitioning).
- [Installing](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
  - Partitions mounting.
  - Cloning your configuration.
  - Creating a standard configuration.
  - Make changes to the generated module.
  - Installation.

As you can see, most of the steps are described in the
[NixOS manual](https://nixos.org/manual/nixos/unstable/#sec-installation-manual).
So all you need to do is follow the manual step by step, up to point 4 in the
[installing section](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
Here you will be asked to generate a configuration, you do not need to do this,
instead follow the steps below:

- Run a shell with `git`, run `nix-shell -p git` command.
- Now let's clone your configuration to your home directory:
  ```bash
  mkdir -p /mnt/home
  mkdir -p -m 0700 /mnt/home/<userName>
  git clone <urlToYourRepo> /mnt/home/<userName>/nixos-configuration
  cd /mnt/home/<userName>/nixos-configuration
  ```
- Generate a default configuration:
  ```bash
  nixos-generate-config --root /mnt --dir modules/nixos/configurations/<hostName>
  git add -AN # flake commands only see files placed in the index
  ```
- Now make changes to the generated `configuration.nix` file. Follow the advice
  in step 4 of the section
  [installing section](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
- Do the installation:
  ```bash
  # uncomment `--no-root-passwd`, if your configuration containes
  # `users.users.root.hashedPassword` option
  nixos-install --flake /mnt/home/<yourUsername>/nixos-configuration#<hostName> # --no-root-passwd
  ```
- Change the owner of your home directory
  ```bash
  nixos-enter
  chown -R <userName>:users /home/<userName>
  exit
  ```
- `reboot` if everything went well

# Basic system operation

This template contains several aliases that may be useful for system management.
Note that some of the following commands assume that your configuration is
stored in the path specified in the
[aliases profile](/modules/profiles/aliases.nix#L3):

- `jnp`, jump to your system's nixpkgs directory, this is useful for researching
  nixpkgs.
- `nupdate`, update all your flake inputs (flake dependencies) and commit those
  changes. Note: this will not update your system, only the inputs of your
  flake. You must use the `nswitch`/`nboot` commands to build and switch to the
  updated configuration.
- `nclear`, removes all old system generations and other unused derivatives from
  `/nix/store`.
- `nswitch`, build the configuration and activate it. This will restart systemd
  services, recreate package symlinks, and so on. Note that some changes cannot
  be successfully applied without a reboot.
- `nboot`, same as `nswitch`, but activates the system on the next boot.

Sometimes you may want to quickly try out an application. To do this, you can
use the following commands:

- `nix shell nixpkgs#<pkgName> nixpkgs#<otherPkg>`, run a shell in which the
  specified packages are available. This can also be used as a
  `nix shell nixpkgs#<pkgName> -c pkg-command args` to simply run a command.
- `nix run nixpkgs#<pkgName>`, this will run the main program of the package.
