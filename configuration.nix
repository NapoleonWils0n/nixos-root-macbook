# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:


let
  # 1. Define your customized dwl package
  myCustomDwlPackage = (pkgs.dwl.override {
    configH = ./dwl/config.h;
  }).overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./dwl/movestack.patch # Using the direct path for the patch
    ];
    # Add any necessary buildInputs if your config.h or patches require them
    # For a bar, you might need fcft for font rendering.
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.libdrm pkgs.fcft ];
  });

  # 2. Create a wrapper script that launches dwl with dwlb as the status bar
  dwlWithDwlbWrapper = pkgs.writeScriptBin "dwl-with-dwlb" ''
      #!/bin/sh
      # launch your customized dwl with its arguments
      exec ${lib.getExe myCustomDwlPackage} -s "${pkgs.dwlb}/bin/dwlb -font \"monospace:size=16\"" "$@"
    '';
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "castor"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.hostId = "37725d60";

  # Set your time zone.
  time.timeZone = "Europe/London";

  # broadcom fix permitted insecure packages
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "broadcom-sta" # aka “wl”
    ];

#  system.autoUpgrade = {
#    enable = true;
#    flake = inputs.self.outPath; # Points to the flake in the Nix store
#    flags = [
#      "--update-input" "nixpkgs" # Update the nixpkgs input (will show deprecation warning)
#      "-L" # Print build logs
#    ];
#    dates = "00:00"; # Example: Run at midnight
#    randomizedDelaySec = "45min"; # Add a random delay
#  };

  # nix garbage collection
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  console.keyMap = "us";
  nixpkgs.config.allowUnfree = true;

  # --- XDG Desktop Portal Configuration for Wayland ---
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true; # Recommended for better portal integration
    wlr.enable = true;       # This is the crucial part for wlroots compositors
  };


  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;
  xkb = {
  layout = "gb";
  variant = "mac";
  };
  };

  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;

  thermald.enable = true;
  printing.enable = false;
  libinput.enable = true;
  openssh.enable = true;

  pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # gnome
  gnome = {
    localsearch.enable = false;
  };
};

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
     ];
    };
};
  

  # Enable touchpad support (enabled default in most desktopManager).

  users.users.djwilcox.initialPassword = "password";
  users.mutableUsers = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.djwilcox = {
    isNormalUser = true;
    extraGroups = [ "wheel audio networkmanager video" ]; # Enable ‘sudo’ for the user.
  };

  users.users.djwilcox.shell = pkgs.zsh;
  security.sudo.enable = true;

# rtkit for audio
security.rtkit.enable = true;

# doas
security.doas = {
  enable = true;
  extraConfig = ''
    # allow user
    permit keepenv setenv { PATH } djwilcox
    
    # allow root to switch to our user
    permit nopass keepenv setenv { PATH } root as djwilcox

    # nopass
    permit nopass keepenv setenv { PATH } djwilcox

    # nixos-rebuild switch
    permit nopass keepenv setenv { PATH } djwilcox cmd nixos-rebuild
    
    # root as root
    permit nopass keepenv setenv { PATH } root as root
  '';
};

  # gnome remove packages
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-text-editor
  ]) ++ (with pkgs; [
    cheese # webcam tool
    gnome-calendar
    gnome-contacts
    gnome-clocks
    gnome-music
    gnome-maps
    epiphany # web browser
    geary # email reader
    gnome-characters
    gnome-weather
    simple-scan
    totem # video player
  ]);

  # programs.firefox.enable = true;
  programs = {
  # dwl
  dwl = {
    enable = true;
    # Tell the dwl module to use our wrapper script as the dwl executable
    package = dwlWithDwlbWrapper;
  };

  zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
   };
   dconf.enable = true;
   mtr.enable = true;

   gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
};


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; lib.filter (p: ! (lib.hasAttr "providedSessions" p && p.providedSessions == [ "dwl" ])) [
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

  #dwl
  dwlb 
  xdg-desktop-portal-wlr
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.

  # List services that you want to enable:

  # Enable the OpenSSH daemon.

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 6881 ];
  networking.firewall.allowedUDPPorts = [ 6882 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  #system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}
