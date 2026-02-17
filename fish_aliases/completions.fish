# Completions for gittools
complete -c gittools -f # Disable file completion
complete -c gittools -n "__fish_use_subcommand" -a init-existing -d "Initialize local directory as Git repo"
complete -c gittools -n "__fish_use_subcommand" -a remote-add     -d "Add a new remote and push"
complete -c gittools -n "__fish_use_subcommand" -a remote-delete  -d "Delete an existing remote"
complete -c gittools -n "__fish_use_subcommand" -a local-prune    -d "Remove local branches gone on remote"

# Completions for other shelltools
complete -c ssgpt -d "Interactive shell GPT prompt"
complete -c gitreset -d "Reset to origin branch"
complete -c gitupdatelast-add-amend-forcewithlease -d "Add, amend, and force push"
complete -c fritzbox-tunnel -d "Establish tunnel to FritzBox"
complete -c srcvenv -d "Activate local virtual environment"
complete -c mount_share -d "Mount Roboception shares"
complete -c unmount_share -d "Unmount Roboception shares"
