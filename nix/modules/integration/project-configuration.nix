{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {
  options.project = {
    name = mkOption {
      default = "";
    };

    version = mkOption {
      default = "";
    };

    authorEmail = mkOption {
      default = "";
    };

    rootFolder = mkOption {
      default = "";
    };

    domain = mkOption {
      default = "";
    };

    subdomains = mkOption {
      default = ["*"];
    };

    make-sub-domain = mkOption {
      default = null;      
    };

    hash = mkOption {
      default = ""; 
    };

    resources.yaml.folder = mkOption {
      default = "";
    };

    repositories = {
      k8s-resources = mkOption {
        default = "";
      };
      code-repository = mkOption {
        default = "";
      };
    };
  };

  config = mkMerge [
    ({ project.hash = 
        builtins.hashString "sha1" 
          (builtins.toJSON cfg.kubernetes.resources.list);

        output = {project = cfg.project;};
    })
  ];
}