# duplicity-wrapper
Bash script and systemd service to help automate duplicity backup jobs.

## Integration with systemd
Create a simlink of `backup-duplicity.service` in `/etc/systemd/system/`:
```
sudo ln -s /path/to/duplicity-wrapper/backup-duplicity.service /etc/systemd/system/backup-duplicity.service
```

Reload systemd daemons:
```
sudo systemctl daemon-reload
```

## Usage
Start backup job:
```
systemctl start backup-duplicity
```

Check logs:
```
journalctl -u backup-duplicity
```
