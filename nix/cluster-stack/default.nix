{
  pkgs, 
  stdenv,
  env-config, 
  callPackage,
  writeScript,
  writeScriptBin,
  application,
  log,
  kubenix,
  k8s-resources,
  lib
}:
with kubenix.lib;
rec {
  config = callPackage ./config.nix {
    inherit pkgs;
  };

  cluster-images = config.docker.export;

  k8s-cluster-resources = toYAML (k8s.mkHashedList { 
    items = 
        config.kubernetes.objects
        # has to be postponed - check helm instance -> and attach this
      ;
  });

  k8s-functions-resources = toYAML (k8s.mkHashedList { 
    # TODO make a helper to take all functions
    items = 
        k8s-resources.knative-stack
        ++ application.functions.express-app.config.kubernetes.objects;
  });

  images = (lib.flatten application.function-images) ++ cluster-images;
}
