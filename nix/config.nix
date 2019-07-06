{
  rootFolder, 
  env,
  brigadeSharedSecret,
  aws-profiles,
  log,
  nix-gitignore,
  lib
}:
let
in
rec {
  inherit 
    rootFolder 
    env;

  aws-credentials = aws-profiles.default; # default aws profile

  # knative-serve = import ./modules/knative-serve.nix;
  projectName = "future-is-comming";
  version = "0.0.1";
  gitignore = nix-gitignore.gitignoreSourcePure [ "${rootFolder}/.gitignore" ];

  ssh-keys = {
    bitbucket = {
      pub = toString ~/.ssh/bitbucket_webhook.pub;
      priv = toString ~/.ssh/bitbucket_webhook;
    };
  };

  secrets = "${rootFolder}/secrets.json";

  kubernetes = {
    version = "1.13";
    namespace = {
      functions = "functions";
      infra = "local-infra";
      brigade = "brigade";
      istio = "istio-system";
      knative-monitoring = "knative-monitoring";
      knative-serving = "knative-serving";
    };
  };

  imagePullPolicy = "IfNotPresent";

  is-dev = env == "dev";

  s3 = {
    worker-cache = "${projectName}-worker-binary-store";
  };
  
  repository = {
    location = "bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative"; # this name cannot be longer than 64
    git = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
  };

  brigade = {
    sharedSecret = brigadeSharedSecret;
    project-name = "embracing-nix-docker-k8s-helm-knative";
    pipeline = "${rootFolder}/pipeline/infrastructure.ts"; 
  };

  # INFO this is a bit tricky - knative is not able to reach localhost
  # possible workaround -> https://github.com/triggermesh/knative-local-registry/blob/master/sysadmin/nodes-etc-hosts-update.yaml
  docker = rec {
    knative = {
      registry = 
        if is-dev 
          then "docker-registry.local-infra.svc.cluster.local" 
          else "";
    };

    local-registry = {
      host = "localhost";
      clusterPort = 80;
      exposedPort = 32001;
    };

    namespace = env;

    registry = 
      if is-dev
        then "${local-registry.host}:${toString local-registry.exposedPort}"
        else "docker.io/gatehub";

    destination = "docker://damianbaar"; # skopeo path transport://repo

    tag = if is-dev
      then { tag = "dev-build"; }
      else { tag = version; };
  };

  info = rec {
    warnings = lib.dischargeProperties (
      lib.mkMerge [
        (lib.mkIf 
          (brigadeSharedSecret == "") 
          "You have to provide brigade shared secret to listen the repo hooks")
      ]
    );

    infos = lib.dischargeProperties (
      lib.mkMerge [
        (lib.mkIf 
          (is-dev) 
          "You are in dev mode")
      ]
    );
    printWarnings = lib.concatMapStrings log.warn warnings;
    printInfos = lib.concatMapStrings log.info infos;
  };
}