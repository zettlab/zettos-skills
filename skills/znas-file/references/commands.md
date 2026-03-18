# Commands Reference

## Search (AI-first)

```bash
znas search --query '猫'
znas search --query '海边' --scope teams --type image --tag 旅行
```

## NAS Knowledge QA

```bash
znas ask --question '演讲技巧'
znas ask --question '总结最近账单变化'
```

## Browse

```bash
znas file root spaces
znas file root list --json '{"path":"/personal","size":50,"index":0}'
znas file root detail --params '{"path":"/teams/test-space/test-image.jpg"}'
```

## Content Access

```bash
# local readability check (same machine)
test -r /zettos/pool/<pool-id>/teams/test-space/test-image.jpg && echo local-ok

# direct text-like content
znas file file read --params '{"path":"/teams/test-space/test-note.txt"}'

# direct binary/raw bytes
znas file file raw --params '{"path":"/teams/test-space/test-image.jpg"}' -o ./test-image.jpg

# ai retrieval by question (not path-only read)
znas ask --question '总结最近账单变化'
znas file file ai-text --params '{"question":"总结最近账单变化"}'
```

## File/Folder CRUD

```bash
# use a concrete server-returned path for normal child-folder creation
znas file folder create --json '{"path":"/zettos/pool/1/teams/cjz/DATA/cjz/test-folder"}'
znas copy --source '/teams/test-space/test-a.txt' --target '/teams/test-space/archive' --on-conflict skip
znas copy --source '/teams/test-space/a.txt' --source '/teams/test-space/b.txt' --target '/teams/test-space/archive' --on-conflict copy
znas file root rename --json '{"old_path":"/teams/test-space/test-a.txt","new_path":"/teams/test-space/test-b.txt"}'
znas file root delete --json '{"paths":["/teams/test-space/test-b.txt"]}'
znas file file create --json '{"path":"/teams/test-space/test-note.txt","content":"hello"}'
znas file file edit --json '{"path":"/teams/test-space/test-note.txt","content":"hello2"}'
znas file file read --params '{"path":"/teams/test-space/test-note.txt"}'
```

Top-level create note:

- `/personal` root-level create should prefer `znas settings storage-pool user-pools`
- `/teams` root-level create should use `znas settings storage-pool list`
- after the pool is chosen, use `znas file root set-base-path` instead of `znas file folder create`
- personal example:
  `znas file root set-base-path --json '{"folder_name":"旅行资料","pool_name":"pool_2","type":2}'`
- teams example:
  `znas file root set-base-path --json '{"folder_name":"团队资料","pool_name":"pool_2","type":1,"quota_size":-1}'`
- use the returned `data.path` as the concrete created path for later verification or child operations

## Tag/Favorites/Recycle

```bash
znas file tag create --json '{"name":"旅行"}'
znas file tag edit-file-tag --json '{"path":"/teams/test-space/test-image.jpg","tags":[{"id":1,"name":"test-tag"}]}'
znas file favorites add --json '{"paths":["/teams/test-space/test-image.jpg"]}'
znas file recycle restore --json '{"paths":["/teams/test-space/test-old.txt"],"is_all":false}'
```

## Share

```bash
znas remote-access status
znas remote-access enable
znas remote-access show-id
znas file share list
znas file share create --json '{"file_paths":["/teams/test-space/test-image.jpg"],"invalid_time":7}'
znas file share delete --json '{"share_ids":["<share-id>"]}'
```
