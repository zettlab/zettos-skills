# Shared Error Reference

Use this table when command output returns business code errors.

| Code | Name | Meaning | Suggested Action |
| --- | --- | --- | --- |
| 60004 | DIR_NOT_EXISTS | Directory does not exist | Start with virtual roots (`/personal`, `/teams`, `/shares`, `/recycle`), then use exact `data.content[*].path`. |
| 60012 | FILE_OR_DIR_NOT_EXIST | File or directory not found | List parent first and reuse returned path. |
| 60016 | FILE_PERM_READ_ERROR | Read permission denied | Switch account or scope with read permission. |
| 60017 | FILE_PERM_WRITE_ERROR | Write permission denied | Switch account or scope with write permission. |
| 62002 | FILE_SPACE_FULL_ERROR | Storage full | Free space or move target path to a pool with quota. |
| 64000 | FILE_PARAM_ERROR | Invalid/missing params | Use command `--help` examples and verify required fields. |
| 64001 | FILE_PARAM_ROOT_PATH_PERM_ERROR | Path root security check failed | For physical-path APIs, use `/zettos/pool/...`; avoid `/zettos/raid/...` and system paths. |
| 65002 | FILE_UNKNOWN_DB_ERROR | DB search failure | Prefer `znas search --query ...` and narrow filters/scope. |
