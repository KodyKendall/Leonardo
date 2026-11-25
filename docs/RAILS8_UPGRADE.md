# Rails 8 upgrade: fleet scan and `bin/upgrade-to-0.8` (LP-52)

Moves a box from the 0.7.x images (Rails 7.2) to 0.8.0 (Rails 8.1, Ruby 3.4). Two scripts in
`bin/` (so `bin/update` carries them to every box), plus what the mothership has to do around
them. The box half is built and tested here; the mothership half is not built yet.

## 1. Fleet scan (read-only) — `bin/rails8-fleet-scan`

Run where the fleet SSH keys live:

```bash
bin/rails8-fleet-scan --inventory boxes.csv \
  --never-touch rails/app/models/never_touch.txt --read-only rails/app/models/read_only.txt \
  --exec 'ssh -i ~/.ssh/lxd_node_key ubuntu@{node} lxc exec lp-{box} --' --out rails8_scan.csv
```

- `boxes.csv`: `box,node,owner_tier,ssh_target[,project_dir]` (project_dir defaults to `/home/ubuntu/Leonardo`).
- Output CSV columns: `box,node,owner_tier,image_tags,bucket,auto_fixes,human_fixes,zeitwerk`.
  Buckets: `0_fixes`, `auto_only`, `needs_human`, `skipped` (protected), `scan_failed` (unreachable or error).
- Protected boxes get a `skipped` row and are never connected to. Both lists are required.
- What it changes on a box: nothing in the Leonardo dir, its containers or its database. It
  unpacks the scanner into a `mktemp -d` dir that is removed afterwards, and it **pulls
  `kody06/llamapress-simple:0.8.0` (~5 GB) if the box doesn't have it** — check node disk first.
- `zeitwerk:check` runs in a throwaway 0.8.0 container with no network and the overlay mounted
  read-only, so app initializers cannot reach the box's database.

Classes (see `bin/lib/rails8_scan.rb`): old `enum x:` form, `ActiveSupport::ProxyObject`, and
config keys gone in Rails 8.1 are auto-fixes. `Rails.application.secrets`, two enums in one call,
Devise controller overrides, requires of Ruby 3.4 bundled gems missing from the image, and any
`zeitwerk:check` failure need a human. The stock Leonardo Devise overrides (byte-identical to a
shipped version) are not flagged — they are tested on Devise 5; any edit to them is.

## 2. Per box — `bin/upgrade-to-0.8`

What the mothership does, in order:

1. Copy `never_touch.txt` and `read_only.txt` to the box as `.leonardo/never_touch.txt` and
   `.leonardo/read_only.txt`. Without them the script refuses (fail closed).
2. Take the ZFS snapshot (`create_snapshot`) and keep its id.
3. Over SSH, on the box:
   `bin/upgrade-to-0.8 --snapshot-id <id> --edge-url https://rails-<box>.leo.llamapress.ai`
   (Alternative to step 2: set `UPGRADE_SNAPSHOT_CMD` to a command that prints the id.)
4. Read `.leonardo/upgrade_0_8.json` for `/admin/fleet_versions`, the same way as
   `.leonardo/last_update.json`. Optional push: `UPGRADE_REPORT_CMD` is run with the marker path
   after every write.

Exit codes: `0` upgraded or already upgraded · `10` refused, nothing changed · `1` failed and
rolled back · `2` rollback failed (**page; restore the snapshot**) · `3` already running.

Marker `status` values, in order: `snapshot`, `codemods`, `updating`, `verifying`, `upgraded`;
on failure `rolling_back`, then `rolled_back` or `rollback_failed`. Fields also carry `step`,
`failed_step`, `log_excerpt` (last 20 log lines), `previous_llamabot` / `previous_llamapress`,
`snapshot_id`, `codemod_commit`. Full log: `.leonardo/upgrade_0_8.log`.

Commits it makes in the box repo: `Before Rails 8 upgrade` (only if the tree was dirty) and
`Rails 8 codemods` (only if there were auto-fixes). Rollback adds `Revert "Rails 8 codemods"`.

Health check (step 7): Rails answers 200/302 on :3000, `GET <edge>/users/sign_in` is 200 with a
non-empty body, and a sign-in smoke passes. The smoke account is a throwaway
`rails8-smoke-<random>@example.invalid` user inserted directly (no callbacks, so no emails) with a
random password that only lives in the script and goes over stdin, never argv, env or the log. It
is deleted afterwards, also on failure. An app that forces 2FA for every user will fail the smoke
and roll back.

## Open on the mothership side

- `create_snapshot` must cover the box's Postgres data, not just the overlay — the snapshot is
  the only undo for migrations that ran on 8.1.
- `/admin/fleet_versions` needs to read `upgrade_0_8.json` (or take the hook's push).
- Paging on `rollback_failed` / exit 2.
