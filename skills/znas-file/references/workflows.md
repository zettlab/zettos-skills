# Workflows

## Content-driven task (local-first)

1. Run search first and inspect each result's access fields:
   - `local_exists`
   - `local_readable`
   - `preferred_access`
2. If `local_readable=true`, read from local path directly (same machine).
3. Only if local read fails/unavailable, fallback to NAS APIs:
   - text-like: `znas file file read --params '{"path":"<full-path>"}'`
   - binary/raw: `znas file file raw --params '{"path":"<full-path>"}' -o <local-file>`
4. For question-answering over NAS knowledge, use `znas ask --question '<text>'`.
5. Do not use `znas file file ai-text` for path-only read; it requires `question`.

## Organize one folder safely

1. Read current entries:
   - `znas file root list --json '{"path":"/zettos/pool/1/teams/cjz/DATA/cjz","size":100,"index":0}'`
2. Create destination folder:
   - `znas file folder create --json '{"path":"/zettos/pool/1/teams/cjz/DATA/cjz/organized"}'`
3. Copy files with the high-level workflow when the user wants to keep the originals:
   - `znas copy --source '/zettos/pool/1/teams/cjz/DATA/cjz/test-a.jpg' --target '/zettos/pool/1/teams/cjz/DATA/cjz/organized' --on-conflict skip`
4. Rename/move files one by one only when the user explicitly wants relocation instead of copy:
   - `znas file root rename --json '{"old_path":"/zettos/pool/1/teams/cjz/DATA/cjz/test-a.jpg","new_path":"/zettos/pool/1/teams/cjz/DATA/cjz/organized/a.jpg"}'`
5. Copy guardrails:
   - destination must be a directory
   - do not copy a folder into itself or one of its subdirectories
   - prefer `znas copy` over raw `znas task file-op create`
6. Verify:
   - `znas file root list --json '{"path":"/zettos/pool/1/teams/cjz/DATA/cjz/organized","size":100,"index":0}'`

## Top-level create under `/personal` or `/teams`

1. If the target is `/personal`, prefer:
   - `znas settings storage-pool user-pools`
   - if unavailable in the current environment, fall back to `znas settings storage-pool list`
2. If the target is `/teams`, refresh:
   - `znas settings storage-pool list`
3. Keep only pools verified as healthy/writable on the current backend.
4. If multiple eligible pools exist and the user did not already specify a default pool, ask which pool to use.
5. After the pool is chosen, create the root-level folder with `znas file root set-base-path`.
   - personal:
     `znas file root set-base-path --json '{"folder_name":"旅行资料","pool_name":"pool_2","type":2}'`
   - teams:
     `znas file root set-base-path --json '{"folder_name":"团队资料","pool_name":"pool_2","type":1,"quota_size":-1}'`
6. Use the returned `data.path` as the concrete created path for verification, upload continuation, or later child operations.
7. Do not run `/personal` or `/teams` aggregate `list` just to reinterpret the chosen pool.
8. Once the user is already inside a concrete path returned by the server, do not ask for pool selection again for child-folder creation there.

## External share workflow

1. Check remote-access prerequisite:
   - `znas remote-access status`
2. If disabled, enable it first:
   - `znas remote-access enable`
3. Inspect or set remote access ID if needed:
   - `znas remote-access show-id`
   - `znas remote-access set-id --id <value>`
4. Create share only after remote access is enabled:
   - `znas file share create --json '{"file_paths":["/teams/test-space/test-image.jpg"],"invalid_time":7}'`
5. Verify the returned link really opens, then clean it up:
   - `znas file share delete --json '{"share_ids":["<share-id>"]}'`
