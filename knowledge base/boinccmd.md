# Boinccmd

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Connect to specific clients.
# Default hostname: 'localhost'.
# Default password: contents of './gui_rpc_auth.cfg'.
boinccmd --host 'client.fqdn' --passwd 'password' …

# Use project managers.
boinccmd --acct_mgr attach 'http://bam.boincstats.com' 'username' 'password'
boinccmd --acct_mgr info
boinccmd --acct_mgr sync
boinccmd --acct_mgr detach

# Reread the configuration files.
# '--read_cc_config' also includes any 'app_config.xml' file existing in the
# projects' folders.
boinccmd --read_cc_config
boinccmd --read_global_prefs_override

# Get the clients' status.
boinccmd --get_simple_gui_info
boinccmd --get_state

# Get the clients' messages.
# A.K.A. logs.
boinccmd --get_messages

# List the current tasks.
boinccmd --get_tasks
boinccmd --get_tasks | grep -i -C 8 'executing'

# Request projects' updates.
boinccmd --project http://www.worldcommunitygrid.org/ update

# Get file transfers.
boinccmd --get_file_transfers

# Retry file transfers.
boinccmd --file_transfer \
  'https://www.sidock.si/sidock/' \
  'corona_RdRp_v2_sidock_00475839_r2_s-20_0_r356677380_0' \
  retry

# Retry deferred network communications.
boinccmd --network_available

# Toggle getting work units from projects.
boinccmd --project http://www.worldcommunitygrid.org/ allowmorework
boinccmd --get_project_status \
| grep "master URL" \
| awk -F ": " '{print $2}' \
| xargs -n 1 -t -I {} boinccmd --project {} nomorework

# Set run modes.
# 'always' = do work or transfer files always.
# 'auto' = do work or transfer files when allowed by the preferences.
# 'never' = do not work nor transfer files.
# Unless a duration in seconds is given after the mode, the change is permanent.
boinccmd --set_run_mode 'always'
boinccmd --set_gpu_mode 'auto' '10'
boinccmd --set_network_mode 'never' '600'

# Run from containers.
docker run --rm --name 'boinc' 'boinc/client' \
  boinccmd --host 'client.fqdn' --passwd '123' --get_messages
```

## Gotchas

- If not given explicitly, `boinccmd` looks for the password in the `gui_rpc_auth.cfg` file in the same directory it is launched from.

## Further readings

- [Boinccmd tool]
- [Boinc]

<!--
  References
  -->

<!-- Knowledge base -->
[boinc]: boinc.md

<!-- Upstream -->
[boinccmd tool]: https://boinc.berkeley.edu/wiki/Boinccmd_tool
