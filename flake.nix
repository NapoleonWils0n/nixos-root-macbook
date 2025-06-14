{
  description = "NixOS configuration for MacBook Air 2011";

  inputs = {
    # NixOS official package source, pinned to the nixos-unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs,... }@inputs: {
    # Define a NixOS system configuration
    # Replace 'macbook-air-2011' with your actual hostname
    nixosConfigurations.castor = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # Specify the system architecture
      modules = [
        # Import your existing configuration files
       ./configuration.nix
      ];
    };
  };
}
