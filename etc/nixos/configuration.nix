{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # system auto upgrade
  system.autoUpgrade = {
      enable = true;
      dates = "daily";
      allowReboot = false;
  };

  # nix gc
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Bootloader.
  boot = {
  loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
    };
    cleanTmpDir = true;
    # Setup keyfile
    initrd = {
    secrets = {
      "/crypto_keyfile.bin" = null;
      };
    # Enable swap on luks
    luks.devices = {
      "luks-cbf2570f-8c18-416f-a4a2-f541a398325b".device = "/dev/disk/by-uuid/cbf2570f-8c18-416f-a4a2-f541a398325b";
      "luks-cbf2570f-8c18-416f-a4a2-f541a398325b".keyFile = "/crypto_keyfile.bin";
      };
    };
  };

  # networking
  networking = {
    hostName = "castor"; # Define your hostname
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 6881 ];
      allowedUDPPorts = [ 6882 ];
    };
  };


  # Set your time zone.
  time.timeZone = "Europe/London";

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

  # services
  services = {
    xserver = {
    # Enable the X11 windowing system.
    enable = true;
    layout = "gb";
    xkbVariant = "mac";

    # intel
    videoDrivers = [ "intel" ];

    # exclude xterm
    excludePackages = [ pkgs.xterm ];

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    };
    # gnome
    gnome = {
      tracker-miners.enable = false;
    };
    # disable cups printing
    printing.enable = false;
    # avahi
    avahi.enable = true;
    # mac
    acpid.enable = true;
    mbpfan.enable = true;
    # thermals
    thermald.enable = true;
    openssh.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # gnome remove packages
environment.gnome.excludePackages = (with pkgs; [
  gnome-photos
  gnome-tour
  gnome-text-editor
]) ++ (with pkgs.gnome; [
  cheese # webcam tool
  gnome-calendar
  gnome-contacts
  gnome-clocks
  gnome-music
  gnome-maps
  epiphany # web browser
  geary # email reader
  evince # document viewer
  gnome-characters
  gnome-weather
  simple-scan
  totem # video player
]);

  # Configure console keymap
  console.keyMap = "us";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.djwilcox = {
    isNormalUser = true;
    description = "Daniel J Wilcox";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    packages = with pkgs; [
    ];
  };

  # zsh
  programs = {
  zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    };  
  dconf.enable = true;
  ssh.startAgent = true;
  };

  # zsh
  users.defaultUserShell = pkgs.zsh;
  environment.pathsToLink = [ "/share/zsh" ];

  # powermanagement
  powerManagement.enable = true;

  # hardware
  hardware = {
  cpu.intel.updateMicrocode = true;
  opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      ];
    };
  };

  # doas
  security.doas = {
    enable = true;
    extraConfig = ''
      # allow user
      permit keepenv djwilcox
      
      # mount and unmount drives 
      permit nopass djwilcox cmd mount 
      permit nopass djwilcox cmd umount 
      
      # allow root to switch to our user
      permit nopass setenv { PATH } root as djwilcox
      
      # namespace command
      permit nopass setenv { PATH } djwilcox cmd namespace
      
      # vpn split route
      permit nopass djwilcox cmd vpn-netns
      
      # vpn route
      permit nopass djwilcox cmd vpn-route

      # nixos-rebuild switch
      #permit nopass djwilcox cmd nixos-rebuild
      permit nopass keepenv setenv { PATH } djwilcox cmd nixos-rebuild
      
      # root as root
      permit nopass keepenv setenv { PATH } root as root
    '';
  };
  
  environment.systemPackages = with pkgs; [
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
