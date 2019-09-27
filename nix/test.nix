{pkgs}:
with pkgs;
let  
  test-scenario = {...}: {
    name = "test-scenario";
    nodes = { 
      machine1 = { ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];

        environment.systemPackages = [kail kubectl-debug]; 
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");

      $machine1->succeed("kail --help");
      $machine1->succeed("kubectl-debug --help");
    '';
    };

  # TODO add senario to running any variant of shell
  basic-shell = {...}:{
    name = "basic-shell";
    nodes = { 
      machine1 = { pkgs, ... }: { 
        imports = [
          <nixpkgs/nixos/modules/profiles/minimal.nix>
          <nixpkgs/nixos/modules/profiles/headless.nix>
        ];
      }; 
    };
    testScript = ''
      startAll

      $machine1->waitForUnit("default.target");
      $machine1->succeed("ls /etc/source");
      $machine1->succeed("nix-shell --help");
    '';
    };
in { 
  smoke.calling-tools = test-scenario;
  shell.able-to-run = basic-shell;
}