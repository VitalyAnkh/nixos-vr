{
  # nix version above 2.20 has a bug: https://github.com/NixOS/nix/issues/10575
  # use this command to mitigate this: nix run nixpkgs#nixVersions.nix_2_20 -- build .#nixosConfigurations.eva.config.system.build.toplevel -I nixos-config=./configuration.nix
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake.url = "github:xremap/nix-flake";
    agenix.url = "github:yaxitech/ragenix";
    firefox.url = "github:nix-community/flake-firefox-nightly";
  };

  outputs = inputs@{ nixpkgs, home-manager, agenix, ... }: {
    nixosConfigurations = {
      eva = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          #./editor/emacs/default.nix
          
          agenix.nixosModules.default

          {
            environment.systemPackages = [
	      agenix.packages.x86_64-linux.default
	      inputs.firefox.packages.x86_64-linux.firefox-nightly-bin
	    ];
          }

          # 将 home-manager 配置为 nixos 的一个 module
          # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.vitalyr = import ./home.nix;

            home-manager.extraSpecialArgs = inputs;
          }
        
        inputs.xremap-flake.nixosModules.default
        /* This is effectively an inline module */
        {

          # Modmap for single key rebinds
          services.xremap.config.modmap = [
            {
              name = "Global";
              remap = { "CapsLock" = "CTRL_L"; }; # globally remap CapsLock to Ctrl
            }
	    {
              name = "Example CTRL_L > CapsLock";
              remap = { "CTRL_L" = "CapsLock"; };
            }
          ];

          # Keymap for key combo rebinds
          services.xremap.config.keymap = [
            #{
            #  name = "Example ctrl-u > pageup rebind";
            #  remap = { "CapsLock" = "CTRL_L"; };
              # NOTE: no application-specific remaps work without features (see configuration)
            #}
          ];
        }
        ];

    };
    };
  };
}
