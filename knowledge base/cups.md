# CUPS

## Table of contents <!-- omit in toc -->

1. [Administration](#administration)
1. [Let users print](#let-users-print)

## Administration

1. Add this line to `/etc/cups/cupsd.conf`

   ```txt
   SystemGroup lpadmin
   ```

1. Restart the CUPS service.
1. Add CUPS administrators to the `lpadmin` group.
1. Make CUPS administrators logout and login again to update their session's permissions.

## Let users print

1. Add CUPS users to the `lp` group.
1. Make CUPS users logout and login again to update their session's permissions.
