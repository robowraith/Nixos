{
  programs.fish.functions = {
    kmerge = {
      body = ''
        set -l port_map apps_cluster 64430 dev_cluster 64431 vagrant_apps_cluster 64438 vagrant_dev_cluster 64439
        set -l kubeconfigs ~/.kube/*.config
        if test -n "$kubeconfigs"
            for cfg in $kubeconfigs
                set -l name (basename $cfg .config)
                set -l tmpfile (mktemp)

                # Rename cluster, context and user to the config filename
                set -x NAME $name
                kubectl --kubeconfig=$cfg config view --raw \
                    | yq e '
                        .clusters[].name = env(NAME) |
                        .clusters[].cluster |= . |
                        .contexts[].name = env(NAME) |
                        .contexts[].context.cluster = env(NAME) |
                        .contexts[].context.user = env(NAME) |
                        .users[].name = env(NAME) |
                        .current-context = env(NAME)
                    ' - \
                    > $tmpfile

                # Update server port if a mapping is defined
                set -l port_idx (contains -i -- $name $port_map)
                if test -n "$port_idx"
                    set -l port $port_map[(math $port_idx + 1)]
                    sed -i -E "s|(server: https://[^:]+:)[0-9]+|\1$port|g" $tmpfile
                end

                mv $tmpfile ~/.kube/$name.config.normalized
            end

            set -l normalized ~/.kube/*.config.normalized
            set -l old_kubeconfig $KUBECONFIG
            set -gx KUBECONFIG (string join : $normalized)
            kubectl config view --flatten > ~/.kube/config.tmp
            mv ~/.kube/config.tmp ~/.kube/config
            set -gx KUBECONFIG $old_kubeconfig

            rm -f $normalized
            echo "Merged and renamed configs: $kubeconfigs"
        else
            echo "No .config files found in ~/.kube"
        end
      '';
      description = "Merge all ~/.kube/*.config files into ~/.kube/config, renaming cluster/context/user to filename and updating server ports";
    };
    md = {
      body = ''
        mkdir $argv[1] && cd $argv[1]
      '';
      description = "Create directory and cd into it";
    };
  };
}
