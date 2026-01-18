_:{
  programs.k9s = {
    enable = true;
    aliases = {
      dp = "deployments";
      sec = "v1/secrets";
      jo = "jobs";
      cr = "clusterroles";
      crb = "clusterrolebindings";
      ro = "roles";
      rb = "rolebindings";
      np = "networkpolicies";
    };
    settings = {
      k9s = {
        liveViewAutoRefresh = true;
        refreshRate = 2;
        maxConnRetry = 5;
        enableMouse = false;
        enableImageScan = false;
        ui = {
          headless = false;
          logoless = true;
          crumbsless = false;
          noIcons = false;
        };
        view = {
          allNamespaces = true;
          favNamespaces = [
            "monitoring"
            "kube-system"
            "longhorn-system"
          ];
        };
        readOnly = false;
        noExitOnCtrlC = false;
        shellPod = {
          image = "busybox:1.35.0";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "100Mi";
          };
        };
        skipLatestRevCheck = false;
        logger = {
          tail = 100;
          buffer = 5000;
          sinceSeconds = 60;
          fullScreenLogs = false;
          textWrap = false;
          showTime = false;
        };
        currentContext = "development-cluster";
        currentCluster = "development-cluster";
        keepMissingClusters = false;
        thresholds = {
          cpu = {
            critical = 90;
            warn = 70;
          };
          memory = {
            critical = 90;
            warn = 70;
          };
        };
        screenDumpDir = "/tmp/k9s-screens-joachim";
        disablePodCounting = false;
      };
    };
  };
}
