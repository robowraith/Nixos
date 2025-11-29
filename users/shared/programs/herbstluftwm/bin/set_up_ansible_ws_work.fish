#! /usr/bin/env fish


set ansibledir ~/code/ansible
set vagrantdir "$ansibledir/vagrant"

/usr/bin/ssh tunnel_k8s_production_cluster &
/usr/bin/ssh tunnel_k8s_development_cluster &

while ! kubectl get nodes --kubeconfig="/home/joachim/.kube/application-cluster.config" --context=application_cluster
end

# rules
hc rule title="k9s_ansible" tag="right"
hc rule title="nvim_ansible" tag="main"
hc rule title="term_ansible" tag="left"
hc rule title="vagrant_ansible" tag="left"

# Start applications
hc spawn /usr/bin/alacritty \
    --title vagrant_ansible \
    --working-directory $vagrantdir

hc spawn /usr/bin/alacritty \
    --title term_ansible \
    --working-directory $ansibledir

/usr/bin/alacritty \
    --title k9s_ansible \
    --working-directory $ansibledir \
    --command /usr/bin/k9s &

hc spawn /usr/bin/kitty \
    --title nvim_ansible \
    --working-directory $ansibledir \
    --detach /usr/bin/nvim
