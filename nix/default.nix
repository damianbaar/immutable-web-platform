{ 
  sources ? import ./sources.nix,
  use-docker ? false
}:
let
  pkgsOpts = 
    if use-docker
      then { system = "x86_64-linux"; }
      else {};

  rootFolder = ../.;

  # workaround - need to create issue against it
  # is is super important when building on darwin, linux images
  arionPath = "${sources.arion.outPath}/arion.nix";

  tools = self: super: {
    kubenix = super.callPackage sources.kubenix {};
    yarn2nix = super.callPackage sources.yarn2nix {};
    arion = super.callPackage (import arionPath) {};
    find-files-in-folder = (super.callPackage ./find-files-in-folder.nix {}) rootFolder;
  };

  config = self: super: {
    env-config = {
      inherit rootFolder;

      env = "dev";
      helm = {
        namespace = "local-infra";
      };
      docker = {
        registry = "docker.io/gatehub";
        destination = "docker://damianbaar"; # skopeo path transport://repo
      };
    };
  };

  overlays = [
    tools
    config
    (import ./deployment.nix)
  ];
  args = { } // pkgsOpts // { inherit overlays; };
in
  import sources.nixpkgs args