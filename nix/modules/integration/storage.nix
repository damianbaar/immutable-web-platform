{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  imports = [
  ];

  options.storage = {
    enable = mkOption {
      default = true;
    };

    provisioner = mkOption {
      default = "ceph.rook.io/block";
    };

    dataDirHostPath = mkOption {
      default = "";
    };

    backup = {
      schedules = mkOption {
        default = {};
      };
      enable = mkOption {
        default = true;
      };
      bucket = mkOption {
        default = "";
      };
    };
  };

  config = mkIf cfg.storage.enable (mkMerge [
    ({
      checks = ["Enabling storage module"];

      packages = [
        pkgs.velero
        pkgs.restic
      ];
    })
  ]);
}