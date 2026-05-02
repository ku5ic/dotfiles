---
name: backup-patterns
description: >
  Backup patterns for Linux servers and applications covering the 3-2-1 rule,
  rsync file backups, PostgreSQL dumps with pg_dump, encrypted backups with
  restic, retention policies, and restore testing. Use whenever the user asks
  about backups, disaster recovery, data retention, pg_dump, rsync, or restic,
  even if "backup" is not mentioned by name.
---

# Backup Patterns

## When to load this skill

- User asks about backups, data retention, or disaster recovery
- Project uses PostgreSQL and needs a dump strategy
- User asks about rsync, restic, pg_dump, or pg_restore
- User is setting up a cron job for automated backups

## When not to load this skill

- Database replication or high-availability (separate from backup)
- Cloud provider snapshot configuration (AWS EBS, GCP PD)

---

## The 3-2-1 rule

Keep **3** copies of data, on **2** different storage media, with **1** copy offsite.

| Copy           | Example                                               |
| -------------- | ----------------------------------------------------- |
| Primary        | Application data on the server                        |
| Local backup   | Second disk, attached NAS                             |
| Offsite backup | Object storage (S3, Backblaze B2), restic remote repo |

A backup that lives only on the same server as the data is not a backup.

---

## PostgreSQL backups

### pg_dump (single database)

The custom format (`-F c`) is the most versatile: smaller than plain SQL, supports parallel restore, and supports selective restore.

```bash
pg_dump -F c -f /backups/mydb_$(date +%Y%m%d).dump mydb
```

Restore:

```bash
pg_restore -d mydb /backups/mydb_20260502.dump
```

Overwrite an existing database (drops objects before recreating):

```bash
pg_restore -d mydb --clean /backups/mydb_20260502.dump
```

### Flags reference

| Flag                     | Meaning                                         |
| ------------------------ | ----------------------------------------------- |
| `-F c`                   | Custom format (recommended)                     |
| `-F d -f dir/`           | Directory format, enables `-j` parallel workers |
| `-F p`                   | Plain SQL (human-readable, large)               |
| `-f filename`            | Output file or directory                        |
| `-x` / `--no-privileges` | Skip GRANT/REVOKE                               |
| `-s`                     | Schema only (no data)                           |
| `-a`                     | Data only (no schema)                           |
| `-j N`                   | Parallel dump workers (directory format only)   |

### pg_dumpall (all databases + roles)

For full server backup including roles and tablespace definitions:

```bash
pg_dumpall -f /backups/all_$(date +%Y%m%d).sql
```

Restore into a fresh cluster:

```bash
psql -f /backups/all_20260502.sql postgres
```

### Streaming to object storage

Pipe directly to avoid temporary files:

```bash
pg_dump -F c mydb | aws s3 cp - s3://mybucket/backups/mydb_$(date +%Y%m%d).dump
```

---

## File backups with rsync

rsync transfers only changed bytes. Use `--delete` to mirror the source exactly (removes files in dest that no longer exist in source).

```bash
rsync -av --delete /opt/myapp/ /backups/myapp/
```

Key flags:

| Flag               | Meaning                                                              |
| ------------------ | -------------------------------------------------------------------- |
| `-a`               | Archive mode: recursive, preserves permissions, timestamps, symlinks |
| `-v`               | Verbose output                                                       |
| `--delete`         | Remove destination files not in source                               |
| `--exclude`        | Skip paths matching a pattern                                        |
| `-n` / `--dry-run` | Preview changes without applying                                     |

Remote backup over SSH:

```bash
rsync -av --delete /opt/myapp/ deploy@backup-server:/backups/myapp/
```

---

## Encrypted backups with restic

restic deduplicates, compresses, and encrypts backup data. Suitable for offsite backups where the storage provider should not see plaintext.

### Initialize a repository

```bash
export RESTIC_PASSWORD="$(cat /etc/backup-password)"
restic init --repo /backups/restic-repo
```

Store the password separately from the backup data (e.g., in a password manager or a secret manager). Loss of the password means permanent data loss.

### Back up a directory

```bash
restic -r /backups/restic-repo backup /opt/myapp \
  --exclude="*.pyc" \
  --exclude="__pycache__" \
  --tag myapp
```

### Back up a database via pipe

```bash
pg_dump -F c mydb | restic -r /backups/restic-repo backup --stdin \
  --stdin-filename mydb.dump \
  --tag postgres
```

### Retention policy

Remove old snapshots and free space:

```bash
restic -r /backups/restic-repo forget \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 12 \
  --prune
```

Preview what would be removed:

```bash
restic -r /backups/restic-repo forget \
  --keep-daily 7 --keep-weekly 5 --keep-monthly 12 \
  --dry-run
```

### List and restore snapshots

```bash
restic -r /backups/restic-repo snapshots
restic -r /backups/restic-repo restore latest --target /tmp/restore
```

---

## Automating with cron

```cron
# /etc/cron.d/backups
# Database dump at 2am daily
0 2 * * * root pg_dump -F c -f /backups/mydb_$(date +\%Y\%m\%d).dump mydb

# restic backup and prune at 3am daily
0 3 * * * root restic -r /backups/restic-repo backup /opt/myapp --tag myapp
30 3 * * * root restic -r /backups/restic-repo forget --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --prune
```

Set `RESTIC_PASSWORD` in `/etc/environment` or a protected env file sourced by the cron job. Never put the password in the crontab line.

---

## Testing restores

A backup never tested is not a backup. Test restore procedures on a schedule:

1. Restore to a separate location (`/tmp/restore`, a staging server)
2. Verify data integrity (row counts, application startup, spot checks)
3. Document the restore time so you know the RTO before an incident

```bash
# Test PostgreSQL restore
pg_restore -d mydb_test /backups/mydb_20260502.dump
psql mydb_test -c "SELECT count(*) FROM orders;"

# Test restic restore
restic -r /backups/restic-repo restore latest --target /tmp/restore-test
```

---

## Anti-patterns

**failure: backup stored only on the same server as the data**
A hardware failure, ransomware infection, or accidental `rm -rf` destroys both. The offsite copy in 3-2-1 exists for exactly this case.

**failure: backup never tested with a restore**
A corrupted or incomplete backup discovered during an incident is worse than no backup because it delays the decision to use other recovery options.

**warning: plain SQL format for large databases**
`-F p` (plain SQL) is the slowest to dump and restore, and cannot use `-j` parallel restore workers. Use `-F c` (custom) or `-F d` (directory) for any database over a few hundred MB.

**warning: pg_dump password in a shell script**
Putting the password in a script as `PGPASSWORD=secret pg_dump ...` leaks it into process listings. Use `~/.pgpass` or a `PGSERVICE` entry in `pg_service.conf` instead.

**warning: restic password lost**
restic encryption is strong enough that a lost password means permanent data loss. Store the password in a separate, durable location (password manager, printed and stored offsite).

**info: no retention policy on backups**
Without forget/prune, backup storage grows unboundedly. Define and automate a retention policy from day one.

---

## References

- https://restic.readthedocs.io/en/latest/
- https://www.postgresql.org/docs/current/app-pgdump.html
- https://www.postgresql.org/docs/current/app-pgrestore.html

> Verify restic flags against the version you have installed; restic self-update keeps the binary current.
