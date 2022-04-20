# Boinccmd

## TL;DR

```shell
# use a project manager
boinccmd --acct_mgr attach http://bam.boincstats.com myAwesomeUsername myAwesomePassword
boinccmd --acct_mgr info
boinccmd --acct_mgr sync
boinccmd --acct_mgr detach

# get the host status
boinccmd --get_simple_gui_info
boinccmd --get_state

# list the current tasks
boinccmd --get_tasks
boinccmd --get_tasks | grep -i -C 8 executing

# toggle getting work units from a project
boinccmd --project http://www.worldcommunitygrid.org/ allowmorework
boinccmd --get_project_status | grep "master URL" | awk -F ": " '{print $2}' | xargs -n 1 -t -I {} boinccmd --project {} nomorework
```

## Gotchas

`boinccmd` looks for the `gui_rpc_auth.cfg` file in the same directory it is launched from.
