# Existing Server State — Fill in BEFORE reset

Inventory what's on the server now so you can decide what to back up.

## VMs / LXCs currently running

| Name | OS | Purpose | Keep? | Backup location |
|------|----|----|-------|----|
| | | | | |
| | | | | |
| | | | | |

## Important data on the host

- [ ] /root or home directories — anything personal
- [ ] /etc — custom configs you'd want to recreate
- [ ] Docker volumes / Compose files
- [ ] Database dumps
- [ ] SSH keys (`/root/.ssh/`, `/home/*/.ssh/`)
- [ ] TLS certs / Let's Encrypt
- [ ] Cron jobs (`crontab -l` for each user)

## Services to recreate later

| Service | Config notes | Priority |
|---------|--------------|----------|
| | | |
| | | |

## Backup destinations

- [ ] External drive: _________________
- [ ] Cloud (S3/GDrive/etc): _________________
- [ ] Verified backup readable on another machine

## Final pre-reset confirmation

- [ ] All "Keep? = Yes" rows above are backed up
- [ ] Confirmed at least ONE backup is readable from a different machine
- [ ] Wrote down hostnames/IPs of services so you can rebuild
