---
name: znas-file
description: "Call zettos-file APIs through znas for CRUD, upload, share, and metadata operations."
---

# znas file

> Prerequisite: read `../znas-shared/SKILL.md`.

## References

- `./references/commands.md`
- `./references/errors.md`
- `./references/workflows.md`

## Capability Summary

- Browse and query NAS files (`list/detail/spaces/history/search/exif`).
- High-level user search via `znas search` (default hybrid keyword+ai-visual+ai-semantic).
- NAS knowledge QA context retrieval via `znas ask` (`/v1/file/aiText`).
- High-level copy via `znas copy` (task `file_op` with CLI guardrails).
- File/folder CRUD (`create/edit/rename/delete`).
- Uploads (chunk upload endpoints + high-level `znas upload`).
- Share operations (auth and noauth-share routes).
- Remote-access prerequisite management for external sharing.
- Metadata operations (tags/favorites/rate/recycle).

## Onboarding Script (Use This in Conversation)

1. Ask for gateway URL (if unknown).
2. Run `znas --base-url <gateway> auth probe`.
3. Run login command.
4. Discover spaces: `znas file root spaces`.
5. Start from virtual read-only paths (`/personal`, `/teams`, `/shares`, `/recycle`), not `/`.
6. For user search intents, run `znas search --query <text>` first (global scope by default).
7. For NAS knowledge Q&A intents, run `znas ask --question <text>`.
8. Before external sharing, check `znas remote-access status` and enable it if needed.
9. For copy intents, prefer `znas copy` instead of low-level task routes.
10. Only then perform write/delete/upload/share actions after explicit confirmation.

## Freshness Rules (Critical)

1. For current file facts, rerun a `znas` read command before answering.
2. This applies to:
   - current spaces or virtual roots
   - current folder entries or item counts
   - current search hits
   - current share list / favorites / tags / rate / recycle state
3. If the user asks follow-ups like `现在有几个`, `现在还有吗`, `我现在能打开哪些地方`, or says they just uploaded, deleted, moved, or shared something, treat earlier results as stale.
4. Previous results may supply an exact `path`, `share id`, or filter values for the next query.
   - They do not justify reusing the old count/list/status.
5. If a write or external action just happened, re-read and then answer.
   - request accepted is not the same as latest verified state

## Copy Workflow (Critical)

User-facing copy should go through `znas copy`, not `znas task file-op create`, unless you are debugging raw backend task payloads.

1. Preferred command:
   - `znas copy --source '<path>' --target '<directory>' --on-conflict skip`
2. `--source` is repeatable:
   - `znas copy --source '/teams/demo/a.txt' --source '/teams/demo/b.txt' --target '/teams/demo/archive'`
3. `--target` is the destination directory, not a renamed final file path.
4. Conflict modes:
   - `skip`: keep destination item and skip conflicting copy
   - `copy`: create a renamed duplicate when names conflict
   - `overwrite`: replace destination item
5. CLI default is `skip` because there is no interactive popup flow in CLI mode.
6. Guardrails:
   - cannot copy to the same directory
   - cannot copy a folder into itself
   - cannot copy a folder into one of its subdirectories
7. After copy submission, re-list the destination if the user asks for the latest contents or counts.

## Content Access Decision (Critical)

When user asks to read/summarize/classify by content, choose one path:

0. Local Access Gate: once a physical path (`/zettos/...`) is known, check local accessibility first.
   - if `local_readable=true` (from `znas search` result), use local tools first.
   - do not start with `znas file file raw` on same machine.
1. Local-first: if file is already accessible in current runtime, use local tools first.
2. Remote text-like content: `znas file file read --params '{"path":"<full-path>"}'`
3. Remote binary/raw content: `znas file file raw --params '{"path":"<full-path>"}' -o <local-file>`
4. NAS knowledge QA retrieval: `znas ask --question '<natural-language-question>'`
5. Low-level equivalent: `znas file file ai-text --params '{"question":"总结最近账单变化"}'`
   - `ai-text` is not path-based read; `question` is required.

## Path Traversal Hard Rules (Read Once)

1. Only first call can use virtual roots (`/personal`, `/teams`, `/shares`, `/recycle`).
2. From second call onward, always use exact `data.content[*].path` returned by previous response.
3. Do not manually concatenate repeated virtual segments.
   - wrong: `/teams/test-space/test-space`
   - correct: list `/teams` first, then copy returned `path` exactly.
4. Exception for top-level folder creation:
   - `/personal` and `/teams` root-level create flows cannot blindly reuse a child path returned by `list`
   - the target pool must be checked and, when needed, chosen first
   - after the pool is chosen, use `znas file root set-base-path` instead of guessing a physical path from aggregate list output

## Virtual Path Policy (Critical)

- Never start first listing from `path="/"` for normal NAS usage.
- First listing should use one of: `/personal`, `/teams`, `/shares`, `/recycle`.
- Use `root spaces` to discover server-provided `ReqInitPath` and follow it.
- `/users` and `/appfolder` are usually admin-oriented.
- `/shared/<username>` is valid for "I shared" tree exploration.

Traversal rule:

- After first virtual-root listing, always use exact returned `data.content[*].path` for next-level calls.
- Do not manually append duplicate folder names like `/teams/<x>/<x>` unless response path explicitly contains it.

Virtual-to-real mapping is handled server-side:

- `/teams/...` -> `/zettos/pool/<pool-id>/teams/<team>/DATA/...`
- `/personal/...` -> `/zettos/pool/<pool-id>/users/<me>/DATA/<me>/...`
- `/users/<name>/...` -> `/zettos/pool/<pool-id>/users/<name>/DATA/...`
- `/shares/...` -> `/zettos/pool/<pool-id>/users/<other>/shared/...`
- `/appfolder/...` -> `/zettos/pool/<pool-id>/virtual_machine/docker/DATA/installed/...`

## Top-Level Folder Create Guardrail (Critical)

This rule is specific to creating a new folder directly under `/personal` or `/teams`.

1. For `/personal` root-level create, follow the frontend flow:
   - prefer `znas settings storage-pool user-pools`
   - if that route is unavailable in the current environment, fall back to `znas settings storage-pool list`
   - after the pool is chosen, call `znas file root set-base-path --json '{"folder_name":"<name>","pool_name":"<pool>","type":2}'`
2. For `/teams` root-level create, follow the frontend flow:
   - refresh with `znas settings storage-pool list`
   - after the pool is chosen, call `znas file root set-base-path --json '{"folder_name":"<name>","pool_name":"<pool>","type":1,"quota_size":-1}'` unless a quota was explicitly requested
3. Eligible pools are only those verified as healthy/writable on the current backend.
   - `status=0` (`ACTIVE`) is required when using `storage-pool list`
   - if the writable file-system state cannot be verified from current fields, do not guess
4. If multiple eligible pools exist and the user has not already said which pool or default pool to use, ask before creating.
5. Do not pick `pool_1` or any other pool just because `/personal` or `/teams` listing happened to return child paths under that pool.
   - aggregate `/personal` or `/teams` list results may contain entries from multiple pools
   - the chosen pool must remain the chosen pool
6. `znas file root set-base-path` returns the concrete created path in `data.path`.
   - use that returned path for follow-up verification, upload continuation, or later child operations
7. Once the target is already a concrete path returned by the server, such as:
   - `/zettos/pool/.../users/<me>/DATA/<me>/...`
   - `/zettos/pool/.../teams/<team>/DATA/<team>/...`
   the pool is already fixed, so child-folder creation under that path does not need a new pool-selection question.
8. If no healthy writable pool is available, stop and explain that safe creation cannot proceed.

## Preferred Search Workflow

- Default search command: `znas search --query <text>`
- It executes keyword + ai_visual + ai_semantic and merges results.
- ai_visual uses `/v1/list`; ai_semantic uses `/v1/ai/getAiSearchByTypes`.
- Global scope is default; add `--scope` only if user asks.
- If a global search already ran, do not recommend teams/personal/shares reruns by default; recommend refining filters first.
- If request has no `--scope/--path`, state clearly that current result is from global search.
- If user intent is NAS question answering, choose `znas ask --question ...` instead of `znas search`.
- Text filter values for `--tag/--city/--equipment` are auto-resolved to backend IDs.
- If unresolved values exist, CLI reports them in `unresolved_*` fields.

## External Share Prerequisite (Critical)

- Before `znas file share create`, run `znas remote-access status`.
- If remote access is disabled, run `znas remote-access enable` first.
- If the environment requires a custom remote access ID, inspect it with `znas remote-access show-id` and set it with `znas remote-access set-id --id <value>`.
- External sharing should fail closed until remote access is ready; do not treat a returned link as usable unless it opens successfully.

Search examples:

```bash
# default: global hybrid search (best for natural language)
znas search --query '猫'

# NAS knowledge question answering (RAG context)
znas ask --question '演讲技巧'

# search only in teams
znas search --query '猫' --scope teams

# combined filters (text names auto-resolved)
znas search --query '海边' --type image --type audio --tag 旅行 --city 上海 --equipment iPhone --rate 5
```

## Usage

```bash
znas file <feature> <command> --params '{}' --json '{}'
```

Read-first examples:

```bash
znas file root spaces
znas file root list --json '{"path":"/personal","size":50,"index":0}'
znas file root list --json '{"path":"/teams","size":50,"index":0}'
```

High-level copy examples:

```bash
znas copy --source '/teams/test-space/test-a.txt' --target '/teams/test-space/archive' --on-conflict skip
znas copy --source '/teams/test-space/a.txt' --source '/teams/test-space/b.txt' --target '/teams/test-space/archive' --on-conflict copy
```

Low-level search examples (debug/manual calls):

```bash
# keyword search in list (use keyword_search)
znas file root list --json '{"path":"/teams","size":20,"index":0,"keyword_search":"猫"}'

# ai semantic search is internal to `znas search` and not exposed as a direct low-level command
znas search --query '骑自行车' --type audio

# exif search (tree_type: 1=device, 2=address)
znas file exif search --params '{"key":"猫","tree_type":1}'
```

## Features

### ai

- `POST` `summary-list` -> `/v1/ai/summaryList` (auth)

### exif

- `GET` `tree` -> `/v1/exif` (auth)
- `GET` `search` -> `/v1/exif/search` (auth)

### favorites

- `POST` `add` -> `/v1/favorites` (auth)
- `DELETE` `remove` -> `/v1/favorites` (auth)
- `GET` `list` -> `/v1/favorites/list` (auth)

### file

- `POST` `upload` -> `/v1/file/upload` (auth)
- `POST` `batch-upload` -> `/v1/file/batch_upload` (auth)
- `GET` `upload-error` -> `/v1/file/getUploadErr` (auth)
- `GET` `upload-tmp-progress` -> `/v1/file/getUploadTmpProcess` (auth)
- `POST` `upload-tmp-progress-batch` -> `/v1/file/batchGetUploadTmpProcess` (auth)
- `POST` `files-exists` -> `/v1/file/postFilesIsExists` (auth)
- `POST` `single-upload` -> `/v1/file/singleUpload` (auth)
- `PUT` `upload-merge` -> `/v1/file/upload/merge` (auth)
- `POST` `create` -> `/v1/file` (auth)
- `PUT` `edit` -> `/v1/file` (auth)
- `GET` `read` -> `/v1/file/str` (auth)
- `GET` `raw` -> `/v1/file/raw` (auth)
- `GET` `ai-text` -> `/v1/file/aiText` (auth)
- `POST` `download-to-nas` -> `/v1/file/download_to_nas` (auth)

### folder

- `POST` `create` -> `/v1/folder` (auth)
- `GET` `path-size` -> `/v1/folder/get_path_size` (auth)

### noauth-share

- `GET` `token` -> `/v1/noauth/share/token` (noauth)
- `GET` `comment-list` -> `/v1/noauth/share/comment/list` (noauth)
- `POST` `comment-create` -> `/v1/noauth/share/comment` (noauth)
- `DELETE` `comment-delete` -> `/v1/noauth/share/comment` (noauth)
- `PUT` `comment-update` -> `/v1/noauth/share/comment` (noauth)
- `GET` `info` -> `/v1/noauth/share/info` (noauth)
- `GET` `file-list` -> `/v1/noauth/share/file/list` (noauth)
- `GET` `file-raw` -> `/v1/noauth/share/file/raw` (noauth)
- `GET` `file-raw-str` -> `/v1/noauth/share/file/rawStr` (noauth)
- `GET` `file-detail` -> `/v1/noauth/share/file/detail` (noauth)
- `POST` `file-download` -> `/v1/noauth/share/file/download` (noauth)
- `HEAD` `file-download-head` -> `/v1/noauth/share/file/download` (noauth)
- `GET` `thumbnail` -> `/v1/noauth/share/file/thumbnail` (noauth)
- `GET` `short-side-webp` -> `/v1/noauth/share/file/getShortSideWebP` (noauth)

### rate

- `PUT` `update` -> `/v1/rate` (auth)
- `PUT` `batch-update` -> `/v1/rate/batchUpdateFileRates` (auth)
- `GET` `get` -> `/v1/rate` (auth)

### recycle

- `DELETE` `delete` -> `/v1/recycle` (auth)
- `PUT` `restore` -> `/v1/recycle` (auth)

### root

- `GET` `windows-upgrade-version` -> `/v1/getWindowsUpgradeVersion` (auth)
- `GET` `spaces` -> `/v1/spaces` (auth)
- `PUT` `rename` -> `/v1/rename` (auth)
- `POST` `list` -> `/v1/list` (auth)
- `DELETE` `delete` -> `/v1` (auth)
- `GET` `detail` -> `/v1` (auth)
- `GET` `exifraw` -> `/v1/exifraw` (auth)
- `POST` `download` -> `/v1/download` (auth)
- `HEAD` `download-head` -> `/v1/download` (auth)
- `GET` `history` -> `/v1/history` (auth)
- `PUT` `set-base-path` -> `/v1/base_path` (auth)
- `GET` `path-quota` -> `/v1/get_path_quota` (auth)
- `GET` `virtual-to-real` -> `/v1/virtual_path_to_real_path` (auth)

### share

- `GET` `list` -> `/v1/share/list` (auth)
- `POST` `create` -> `/v1/share` (auth)
- `DELETE` `delete` -> `/v1/share` (auth)
- `POST` `create-internal` -> `/v1/share/internal` (auth)
- `DELETE` `delete-internal` -> `/v1/share/internal` (auth)
- `GET` `list-internal` -> `/v1/share/internal` (auth)

### tag

- `POST` `create` -> `/v1/tag` (auth)
- `PUT` `edit-file-tag` -> `/v1/tag/file_tag` (auth)
- `POST` `batch-create-file-tags` -> `/v1/tag/batchCreateFileTags` (auth)
- `DELETE` `delete` -> `/v1/tag` (auth)
- `GET` `list` -> `/v1/tag` (auth)
- `PUT` `rename` -> `/v1/tag/rename` (auth)

## Upload

Use high-level upload for chunk + merge flow:

```bash
znas upload --local /path/local.bin --remote /zettos/pool/.../target.bin
```

## Command Guardrails / Allowed Commands

1. Only real `znas` commands are allowed.
2. Allowed commands:
   - `znas search`
   - `znas ask`
   - `znas copy`
   - `znas remote-access status`
   - `znas remote-access enable`
   - `znas remote-access disable`
   - `znas remote-access show-id`
   - `znas remote-access set-id`
   - `znas file root spaces`
   - `znas file root list`
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
