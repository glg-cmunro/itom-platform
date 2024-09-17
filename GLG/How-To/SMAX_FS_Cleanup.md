#### Clear SMAX Logs older than 90 days
```
sudo find /mnt/efs/var/vols/itom/itsma/global-volume/logs/ -name "*.log" -type f -mtime +90 -delete
```
#### Clear OO Logs older than 90 days
```
sudo find /mnt/efs/var/vols/itom/oo/oo_log_vol/ -name "*.log" -type f -mtime +90 -delete
```
#### Clear SMAX Logs older than 90 days
```
sudo find /mnt/efs/var/vols/itom/itsma/global-volume/logs/ -name "*.log" -type f -mtime +90 -delete
```
