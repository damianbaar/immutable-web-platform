# Generated commands:
# ops-deploy-ec2              
# ops-delete-ec2              
# ops-destroy-ec2             
# ops-ssh-to-*
{
  nixops, 
  writeScript, 
  writeScriptBin, 
  pkgs,
  local,
  rsync,
  lib,
  machines
}:
let
  optionalArgs = "$*";

  cluster-scripts = pkgs.callPackage ./cluster-scripts.nix {
    inherit nixops machines;
  };

  # TODO in case of local machines should not be considered!!!
  create-ssh-variants = let
    make-ssh = name: resource-name: 
      writeScriptBin "ops-ssh-to-${name}-${resource-name}" ''
        ${nixops}/bin/nixops ssh -d ${name} ${resource-name} ${optionalArgs}
      '';

    # TODO should be in machine.nix
    masters = (builtins.attrNames machines.membership) ;
    nodes = 
      (lib.flatten 
          (lib.foldl 
            builtins.concatLists 
            (builtins.attrValues machines.membership) 
            []));
  in
    name: 
      lib.genAttrs  
        (masters ++ nodes) 
        (make-ssh name);

  deployment = {name, configuration, machine}: rec {

      create = writeScriptBin "create-deployment-${name}" ''
        ${nixops}/bin/nixops list | grep "${name}" || \
          ${nixops}/bin/nixops create ${configuration} ${machine} -d ${name}
      '';

      destroy = writeScriptBin "ops-destroy-${name}" ''
        ${nixops}/bin/nixops destroy -d ${name}
      '';

      delete = writeScriptBin "ops-delete-${name}" ''
        ${destroy}/bin/${destroy.name}
        ${nixops}/bin/nixops delete -d ${name}
      '';

      deploy = writeScriptBin "ops-deploy-${name}" ''
        ${create}/bin/${create.name}
        ${nixops}/bin/nixops deploy -d ${name} --kill-obsolete --allow-reboot
      '';

      # copy-contents = writeScriptBin "ops-folder-sync-${name}" ''
      #   ${rsync}/bin/rsync --rsh="${make-ssh}/bin/${make-ssh.name}" $*
      # '';
    } // (create-ssh-variants name) // (cluster-scripts name);
in
{
  deploy-ec2 = deployment {
    name = "ec2";
    configuration = "nixops/deployment.nix";
    machine = "nixops/targets/ec2.nix";
  };

  deploy-vbox = deployment {
    name = "local-deployment";
    configuration = "nixops/deployment.nix";
    machine = "nixops/targets/vbox-cluster.nix";
  };

  deploy-tester = deployment {
    name = "infra-tester";
    configuration = "tester/configuration.nix";
    machine = "targets/tester.nix";
  };
}