# Lower the power consumption on Linux

```sh
echo '0' > '/proc/sys/kernel/nmi_watchdog'
echo 'med_power_with_dipm' > '/sys/class/scsi_host/host0/link_power_management_policy'

# Increase the virtual memory dirty writeback time to help aggregating disk I/O
# together. This reduces spanned disk writes.
# Value is in 1/100s of seconds. Default is 500 (5 seconds).
echo 6000 > '/proc/sys/vm/dirty_writeback_centisecs'
sudo sysctl vm.dirty_writeback_centisecs=6000
```

## Sources

- Arch Wiki's [power management][arch wiki power management] page

<!-- -->
[arch wiki power management]: https://wiki.archlinux.org/title/Power_management
