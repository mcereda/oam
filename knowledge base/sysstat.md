# sysstat

1. [TL;DR](#tldr)
2. [Installation example](#installation-example)
3. [Further readings](#further-readings)
4. [Sources](#sources)

## TL;DR

```sh
# Get all the available stats.
sudo sar -P ALL
```

## Installation example

```sh
sudo apt install sysstat
sudo yum install sysstat

sudo sed -i.bak 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat

sudo systemctl enable --now sysstat.service
sudo systemctl restart sysstat.service

# Wait some time (15-20 mins) for some data to be collected.

sudo sar -P ALL
```

Example output:

```text
Linux 5.10.17-v8+ (raspberrypi)   07/08/21   _aarch64_   (4 CPU)

10:24:12     LINUX RESTART   (4 CPU)

10:25:01        CPU     %user     %nice   %system   %iowait    %steal     %idle
10:35:01        all      0.01     68.97      0.30      0.00      0.00     30.72
10:35:01          0      0.00     91.70      0.20      0.00      0.00      8.09
10:35:01          1      0.00     91.79      0.04      0.00      0.00      8.16
10:35:01          2      0.00     91.96      0.04      0.00      0.00      8.00
10:35:01          3      0.03      0.30      0.91      0.00      0.00     98.76

10:35:01        CPU     %user     %nice   %system   %iowait    %steal     %idle
10:45:01        all      0.09     68.96      0.31      0.00      0.00     30.65
10:45:01          0      0.00     91.88      0.12      0.00      0.00      8.00
10:45:01          1      0.00     54.26      0.49      0.00      0.00     45.25
10:45:01          2      0.00     91.74      0.04      0.00      0.00      8.22
10:45:01          3      0.35     37.90      0.57      0.00      0.00     61.17

Average:        CPU     %user     %nice   %system   %iowait    %steal     %idle
Average:        all      0.05     68.97      0.30      0.00      0.00     30.68
Average:          0      0.00     91.79      0.16      0.00      0.00      8.05
Average:          1      0.00     73.03      0.27      0.00      0.00     26.70
Average:          2      0.00     91.85      0.04      0.00      0.00      8.11
Average:          3      0.19     19.11      0.74      0.00      0.00     79.96
```

## Further readings

- [tutorial]

[tutorial]: http://sebastien.godard.pagesperso-orange.fr/tutorial.html

## Sources

- [webpage]
- [github page]

[github page]: https://github.com/sysstat/sysstat
[webpage]: http://sebastien.godard.pagesperso-orange.fr/
