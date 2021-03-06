{pkgs, config, lib, ...}: 
let
  project = pkgs.project-config.project;
  host-name = config.networking.hostName;
  narCache = "/var/cache/hydra/nar-cache";
  aws = pkgs.project-config.aws;
  store-bucket = aws.s3-buckets.worker-cache;
in 
with lib;
{
  imports = [ 
    ./gc.nix
    ./ssh.nix
    ./services.nix
    ./users.nix
  ];

  options.services.hydra = {
    # services.hydra.debugServer = true;

    # services.hydra.workers = [{ 
    #   hostName = "slave1"; 
    #   maxJobs = 1; 
    #   speedFactor = 1; 
    #   sshKey = "/etc/nix/id_buildfarm"; 
    #   sshUser = "root"; 
    #   system = "x86_64-linux"; 
    # }]

    # environment.etc = pkgs.lib.singleton {
    #   target = "nix/id_buildfarm";
    #   source = ./id_buildfarm;
    #   uid = config.ids.uids.hydra;
    #   gid = config.ids.gids.hydra;
    #   mode = "0440";
    # };

    workers = mkOption {
      default = [{
        hostName = "localhost";
        # INFO https://github.com/NixOS/hydra/issues/568
        systems = [ "builtin" "x86_64-linux" ];
        maxJobs = 4;
        supportedFeatures = ["nixos-test" "kvm" "big-parallel" "benchmark"]; # in case of ec2 kvm is not true
      }];
    };
  };

  config = {
    assertions = singleton {
      assertion = pkgs.system == "x86_64-linux";
      message = "unsupported system ${pkgs.system}";
    };

    networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];

    environment.systemPackages = [ 
      pkgs.zsh
      pkgs.hydra-cli
    ];

    nix = {
      distributedBuilds = true;
      buildMachines = config.services.hydra.workers;
      extraOptions = "auto-optimise-store = true";
    };

    environment.etc = pkgs.lib.singleton {
      target = "nix/id_bitbucket";
      # this is kind a cool
      # source = pkgs.project-config.bitbucket.ssh-keys.priv;
      # FIXME should be in module definition
      source = pkgs.project-config.bitbucket.ssh-keys.location;
      uid = config.ids.uids.hydra;
      gid = config.ids.gids.hydra;
      mode = "0400";
    };

    services.hydra = {
      enable = true;
      useSubstitutes = true;
      hydraURL = config.networking.hostName;
      notificationSender = project.authorEmail;
      buildMachinesFiles = [];
      # locally -> without store: store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/${host-name}/secret
      extraConfig = ''
        store_uri = s3://${store-bucket}?region=${aws.region}&secret-key=/etc/nix/${host-name}/secret&write-nar-listing=1&ls-compression=br&log-compression=br
        nar_buffer_size = ${let gb = 10; in toString (gb * 1024 * 1024 * 1024)}
      '';
      # for prod
      # upload_logs_to_binary_cache = true
      # log_prefix = https://${store-bucket}.s3.amazonaws.com/

      # TODO
      # server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
      # binary_cache_public_uri = https://cache.nixos.org
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      identMap = ''
        hydra-users hydra hydra
        hydra-users root postgres
      '';
      dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    };
  };
}