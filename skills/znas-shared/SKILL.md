---
name: znas-shared
description: "zettos-nas (zettlab) shared onboarding: how to connect gateway, authenticate, and safely run NAS operations via znas."
---

# znas Shared

## References

- `./references/errors.md`
- `../znas-file/references/commands.md`
- `../znas-file/references/workflows.md`

## What This Skill Can Do

- Guide a new user from "not connected" to "can operate NAS".
- Execute zettos-nas file APIs via `znas` (browse/search/copy/CRUD/upload/share/tag/favorites/recycle/rate).
- Diagnose common auth/connectivity failures (wrong gateway, 502 upstream, missing token/account).
- Choose proper content access route (`local tools` vs `file read/raw` vs `znas ask`/`file ai-text`).

## First-Run Flow (Mandatory)

1. Probe gateway/user-auth route:
   - `znas --base-url <gateway> auth probe`
2. Login:
   - `znas --base-url <gateway> auth login --username <name> --password <secret> --keep-logged-in`
3. Verify auth:
   - `znas auth status`
4. Discover virtual spaces first:
   - `znas file root spaces`
5. Start read-only listing from a virtual entry path (not `/`):
   - `znas file root list --json '{"path":"/personal","size":50,"index":0}'`

## Freshness And Re-Query Rules (Critical)

1. For mutable NAS facts, do not answer from conversation memory alone.
2. If the user asks about current state, rerun the matching read command right before answering.
3. Treat prompts like these as mandatory re-query triggers:
   - `现在 / 当前 / 最新`
   - `有几个 / 还有几个 / 有哪些`
   - `是不是开着 / 还在不在 / 状态怎么样`
   - `刚刚我手动改了 / 别人刚改了 / 我刚创建了`
4. Previous turns may tell you which command, path, app id, pool name, or scope to use.
   - They do not replace the new read.
5. After any async or externally changeable action, always re-read before claiming the result:
   - install / update / uninstall
   - create / copy / delete / rename / move / share
   - settings toggles and storage/network changes
6. If refresh fails, say you could not verify the latest state.
   - Do not guess from old output.
7. Only stable product knowledge can be answered without re-query.
   - examples: command syntax, documented workflow, path semantics

## Path Traversal Hard Rules (Read Once)

1. Only first call can use virtual roots (`/personal`, `/teams`, `/shares`, `/recycle`).
2. From second call onward, always use exact `data.content[*].path` returned by previous response.
3. Do not manually concatenate repeated virtual segments.
   - wrong: `/teams/test-space/test-space`
   - correct: list `/teams` first, then copy returned `path` exactly.
4. Exception for top-level create under `/personal` or `/teams`:
   - do not infer the target pool from whichever child path happened to be returned first
   - top-level create needs a fresh storage-pool check and, when needed, an explicit pool choice first
   - after the pool is chosen, use `znas file root set-base-path`; do not go back to aggregate `list` output to override that choice

## Copy Workflow (Critical)

For normal user-facing copy intents, prefer high-level `znas copy` instead of raw task APIs.

1. Use:
   - `znas copy --source '<path>' --target '<directory>' --on-conflict skip`
2. `--source` is repeatable for multi-file copy.
3. `--target` must be the destination directory, not a final renamed file path.
4. Conflict handling:
   - `skip`: keep existing destination entry
   - `copy`: create a renamed copy when the destination already has the same name
   - `overwrite`: replace the destination entry
5. CLI default is `--on-conflict skip` because it is the safest non-interactive behavior.
6. Guardrails:
   - do not copy a folder into itself
   - do not copy a folder into one of its subdirectories
   - do not use low-level `znas task file-op create` for ordinary copy intents unless debugging backend payloads

## Search Strategy (AI-First)

When user asks natural language intent like "找猫/找海边视频/找合同照片":

1. Prefer high-level search:
   - `znas search --query '<text>'`
2. Default mode is hybrid:
   - one keyword attempt + one visual-ai attempt + one semantic-ai attempt
   - visual ai endpoint: `/v1/list` (`ai_search`)
   - semantic ai endpoint: `/v1/ai/getAiSearchByTypes`
3. Default scope is global:
   - do not force `/teams` or `/personal` unless user asks.
   - if command has no `--scope/--path`, explicitly describe it as global search.
4. If user requests scope:
   - use `--scope teams|personal|shares|recycle|users|path`
5. If user requests filter combinations (tag/city/equipment/rate/time/size):
   - pass text values to `--tag/--city/--equipment` and let CLI resolve IDs.
6. If global search already executed:
   - do not suggest rerunning `teams/personal/shares` as default fallback.
   - instead suggest refining query/filter/type/time/rate or asking for explicit scope.
   - especially avoid asking: "要不要我再按 /personal 或 /teams 排查".
7. If user intent is question-answering over NAS knowledge (for example "总结/解释/回答我NAS里的..."):
   - use `znas ask --question '<text>'` (do not replace with search by default).

## Content Access Decision (Critical)

When user asks to read/summarize/classify by file content:

0. Local Access Gate (must run first once you have a physical path like `/zettos/...`):
   - if search/list result reports `local_readable=true`, use local filesystem tools first.
   - do not call `znas file file raw` as first step on same machine.
1. If file is directly accessible on local filesystem:
   - use local tools first (`cat`, `head`, OCR/PDF parsers if available).
   - do not force NAS API round-trip.
2. If file is remote-only on NAS:
   - text-like read: `znas file file read --params '{"path":"<full-path>"}'`
   - binary/raw bytes: `znas file file raw --params '{"path":"<full-path>"}' -o <local-file>`
3. Top-level NAS knowledge QA:
   - `znas ask --question '<natural-language-question>'`
4. Low-level equivalent `znas file file ai-text` is question-driven AI retrieval:
   - required field is `question`
   - do not pass only `path`
   - example: `znas file file ai-text --params '{"question":"总结最近账单变化"}'`

## Virtual Entry Paths (Mandatory)

Always use zettos virtual paths first. Do not start from `path="/"` unless user explicitly asks for full filesystem audit.

- `/personal`: current user's personal space.
- `/teams`: team spaces.
- `/shares`: "shared to me".
- `/shared/<username>`: "I shared" related tree for a specific owner.
- `/recycle`: recycle view (users/teams recycle trees).
- `/users`: admin-oriented user spaces.
- `/appfolder`: app store runtime files (admin-oriented).

Recommended read-only order for first conversation:
1. `znas file root spaces`
2. `znas file root list --json '{"path":"/personal","size":50,"index":0}'`
3. `znas file root list --json '{"path":"/teams","size":50,"index":0}'`
4. `znas file root list --json '{"path":"/shares","size":50,"index":0}'`
5. `znas file root list --json '{"path":"/recycle","size":50,"index":0}'`

Navigation rule after first list:
- Do not manually concatenate virtual subpaths (example: `/teams/a/a`).
- Use the exact next `path` from previous response `data.content[*].path`.

## Virtual-to-Real Mapping Knowledge

Virtual paths are resolved by zettos-file to pool-backed real paths.

- `/teams/...` -> `/zettos/pool/<pool-id>/teams/<team>/DATA/...`
- `/personal/...` -> `/zettos/pool/<pool-id>/users/<me>/DATA/<me>/...`
- `/users/<name>/...` -> `/zettos/pool/<pool-id>/users/<name>/DATA/...`
- `/shares/...` -> `/zettos/pool/<pool-id>/users/<other>/shared/...`
- `/recycle/...` -> recycle directories under users/teams in one or more pools
- `/appfolder/...` -> `/zettos/pool/<pool-id>/virtual_machine/docker/DATA/installed/...`

## Top-Level Create Guardrail (Critical)

When the user wants to create a new folder directly under `/personal` or `/teams`:

1. Follow the product frontend flow, not a guessed path flow.
2. For `/personal` root-level create:
   - prefer `znas settings storage-pool user-pools`
   - if that route is unavailable in the current environment, fall back to `znas settings storage-pool list`
   - after the user chooses a pool, call `znas file root set-base-path --json '{"folder_name":"<name>","pool_name":"<pool>","type":2}'`
3. For `/teams` root-level create:
   - refresh with `znas settings storage-pool list`
   - after the user chooses a pool, call `znas file root set-base-path --json '{"folder_name":"<name>","pool_name":"<pool>","type":1,"quota_size":-1}'` unless a quota was explicitly requested
4. Do not infer or override the chosen pool from `/personal` or `/teams` aggregate `list` output.
   - those list results may contain entries from multiple pools
   - seeing a `pool_1` child first does not mean the whole root is bound to `pool_1`
5. Only offer pools verified as healthy/writable on the current backend.
   - `status=0` (`ACTIVE`) is required when using `storage-pool list`
   - if the writable file-system state cannot be verified from current fields, do not guess
6. If multiple eligible pools exist and the user has not already stated a default pool, ask which pool to use.
7. Once the user is already operating inside a concrete path returned by the server, such as `/zettos/pool/.../DATA/...`, the pool is already chosen.
   - child-folder creation under that concrete path does not need a second pool-selection question
8. If no eligible pool is verified, stop and explain that no safe create target is currently available.

## External Share Prerequisite (Critical)

Before `znas file share create` for external users:

1. Check remote access status:
   - `znas remote-access status`
2. If disabled, enable it first:
   - `znas remote-access enable`
3. If your environment requires a custom remote access ID:
   - inspect: `znas remote-access show-id`
   - set: `znas remote-access set-id --id <value>`
4. Only after remote access is ready should you create and verify an external share link.

## Newbie Communication Rules

1. Default to plain language before jargon.
2. Explain the user goal first, then mention the technical term if it helps.
3. If you must introduce a term, format it as:
   - plain-language explanation first
   - technical name second in parentheses
4. Good examples:
   - say `外网访问` first, then mention `remote access`
   - say `自动对时` first, then mention `NTP`
   - say `电脑访问 NAS 的方式` first, then mention `SMB / FTP / WebDAV / NFS`
   - say `固定外网地址方案` first, then mention `DDNS`
5. When the user is choosing between options, present short choices with a recommended default instead of a long protocol list.
6. Do not assume a first-time user understands storage-pool, file-service, cert, OTA, SMART, rsync, Bonjour, or Time Machine.
7. For first-time users, prefer:
   - what problem this solves
   - whether most people need it
   - what will happen if it is turned on
   - whether confirmation is required
8. In a dedicated zNAS product context, or in an isolated workspace that only exposes zNAS skills:
   - interpret generic file intents like `找照片`, `找文件`, `报销材料`, `我能打开哪些地方`, `我有哪些空间` as NAS intents first
   - prefer `znas search`, `znas ask`, `znas file root spaces`, and virtual-root browsing before any internet search
9. Do not answer those intents by listing the current temp workspace, copied skill files, or local agent sandbox paths unless the user explicitly asks about the workspace itself.
10. If the user truly means something outside NAS and the context does not make that clear, ask one short clarification question instead of jumping to web search.

## Native Command Boundary (Critical)

1. For NAS control-plane or runtime tasks, do not bypass `znas` by falling back to host-native commands.
2. This rule is critical in both supported deployment modes:
   - remote agent controlling another NAS: host-native commands would target the wrong machine
   - local NAS agent running as an unprivileged user: host-native system or Docker commands will fail or incorrectly assume root-level access
3. Forbidden fallback examples:
   - `docker`, `docker compose`, `podman`
   - ad-hoc `curl` to internal service APIs or daemon sockets
   - `systemctl`, `journalctl`, `ip`, `nmcli`, `mount`, `umount`
4. The only allowed local-first shortcut is content reading when the NAS result explicitly says `local_readable=true`.
5. If `znas` cannot complete the task, report that limitation clearly instead of pivoting to host-native commands.

## Authentication Rules

1. Use gateway URL (not internal service URL) whenever possible.
2. Account switching: `znas auth default --account <name>` or global `--account`.
3. For noauth share APIs, provide `--sharing-token`.
4. Token source precedence:
   - `ZETTOS_NAS_CLI_TOKEN`
   - `ZETTOS_NAS_CLI_CREDENTIALS_FILE`
   - encrypted account credentials

## Global Behavior

- Base URL can be set by `--base-url` or `ZETTOS_NAS_CLI_BASE_URL`.
- If not set, CLI attempts runtime gateway file `/zettos/raid/app/runtime/gateway.url`, then falls back to `http://127.0.0.1`.
- File prefix defaults to `/zettos/main/file`.
- System-settings prefix defaults to `/zettos/main/system-settings`.
- Count metric for coverage is `method+path`.

## Command Guardrails / Allowed Commands

1. Only real `znas` commands are allowed.
2. Allowed commands:
   - `znas search`
   - `znas ask`
   - `znas copy`
   - `znas settings storage-pool user-pools`
   - `znas settings storage-pool list`
   - `znas remote-access status`
   - `znas remote-access enable`
   - `znas remote-access disable`
   - `znas remote-access show-id`
   - `znas remote-access set-id`
   - `znas file root spaces`
   - `znas file root list`
   - `znas file root set-base-path`
   - `znas file file read`
   - `znas file file raw`
   - `znas file file ai-text`
   - `znas copy`
   - `znas upload`
   - `znas file root delete`
   - `znas file root rename`
   - `znas file share create`
   - `znas file share delete`
   - `znas file share list`
3. Forbidden fabricated commands:
   - `list_directory`
   - `search videos`
   - `znas gateway connect`
   - `znas file ls`
   - `znas-file share`
4. Confirmation policy:
   - Read operations do not require confirmation by default.
   - Write/delete/share/upload operations must be confirmed before execution.

## Failure Triage

- `status=502` or empty response on `auth probe/login`:
  - Usually wrong gateway URL or upstream unavailable.
  - Re-run with explicit `--base-url`.
- If listing from `/` returns system directories:
  - This is expected filesystem root behavior, but not recommended for NAS onboarding.
  - Switch to `root spaces` + virtual path listing.
- If business code `60004` appears on `root list`:
  - Usually the path was manually composed and does not exist.
  - Re-run using exact `data.content[*].path` from previous response.
- If `root list` search seems ineffective:
  - Use `keyword_search` (not `keyword`) in request JSON.
- If AI route `/v1/ai/getAiSearchByTypes` returns `65002`:
  - likely caused by backend SQL limitation when passing multi `types`.
  - semantic search requests are fanned out internally as single-type calls.
  - prefer `znas search --query <text>`; this is the only public AI search entry.
- If exif search returns parameter error:
  - Ensure `key` + `tree_type` are provided (`1=device`, `2=address`).
- If local requests fail in proxy-heavy environments:
  - CLI disables proxy for loopback hosts automatically.
  - When you manually verify a local app URL with `curl`, unset `http_proxy`, `https_proxy`, and `all_proxy` first.
  - Otherwise a local NAS app may look broken only because the request was routed through an HTTP proxy.
- `no account configured`:
  - run `znas auth login ...` first.
- If external share creation is blocked because remote access is disabled:
  - run `znas remote-access status`
  - then `znas remote-access enable`
  - retry `znas file share create` only after remote access is enabled

## Safety

- Do not log secrets (password/access token/refresh token).
- Prefer read endpoints first when uncertain.
- For write/delete actions, confirm exact target paths before execution.
