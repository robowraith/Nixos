{
  programs.fish.functions = {
    kmerge = {
      body = ''
        set -l kubeconfigs ~/.kube/*.config
        if test -n "$kubeconfigs"
            set -l old_kubeconfig $KUBECONFIG
            set -gx KUBECONFIG (string join : ~/.kube/config $kubeconfigs)
            kubectl config view --flatten > ~/.kube/config.tmp
            mv ~/.kube/config.tmp ~/.kube/config
            set -gx KUBECONFIG $old_kubeconfig
            echo "Merged $kubeconfigs into ~/.kube/config"
        else
            echo "No .config files found in ~/.kube"
        end
      '';
      description = "Merge all ~/.kube/*.config files into ~/.kube/config";
    };
  };
}
