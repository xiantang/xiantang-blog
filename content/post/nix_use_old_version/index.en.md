---
title: "Nixos use old version software"
date: 2024-07-08T23:42:39+08:00
author: "xiantang"
# lastmod: 
tags: ["NixOS"]
categories: ["NixOS"]
# images:
#   - ./post/golang/cover.png
description:
draft: false
---

NixOS users often face situations where the latest software versions have issues, but the NixOS channel only offers the fixed versions. Here's how to use an older version of software:

According to the blog post [How to use old versions of software in NixOS](https://lazamar.github.io/download-specific-package-version-with-nix/), you can follow these steps to use an older software version:

### Search for the old version of the software

Use `https://lazamar.co.uk/nix-versions/` to search for old packages.

For example, to install `hugo` version `v0.60.0`, search for `hugo` and find the desired version, which is [here](https://lazamar.co.uk/nix-versions/?package=hugo&version=0.60.0&fullName=hugo-0.60.0&keyName=hugo&revision=ee355d50a38e489e722fcbc7a7e6e45f7c74ce95&channel=nixpkgs-unstable#instructions).

```nix
let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ee355d50a38e489e722fcbc7a7e6e45f7c74ce95.tar.gz";
  }) {};

  myPkg = pkgs.hugo;
in
```

Add the above code to your `configuration.nix`:

```nix
# { modulesPath, config, pkgs, lib, helix, ... }:
# with lib;
let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ee355d50a38e489e722fcbc7a7e6e45f7c74ce95.tar.gz";
  }) {};

  hugo = pkgs.hugo;
in
# let unstable = import <unstable> { };
#
# in {
```

Then refer to `myPkg` in `environment.systemPackages` of `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  # ...
  myPkg
  # ... ];
```

Run `nixos-rebuild switch` to apply the changes.
