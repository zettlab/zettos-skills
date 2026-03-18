---
name: znas-docker
description: "Call Zettos Docker runtime APIs for overview, config, container/image/network/project management, logs, and terminal command presets."
---

# znas docker

> Use this skill when the user wants Docker runtime information or advanced runtime management from the Docker icon perspective rather than the App Store app-centric view.

## What This Skill Is For

- Read Docker health, version, storage pool, image count, container count, and runtime config.
- Inspect or change Docker runtime config, proxy, registry, and accelerator settings.
- Manage Docker networks.
- Inspect containers, container logs, and update container config.
- Inspect images, pull images, export images, and query registry images/versions.
- Manage Compose projects.
- Manage Docker log records and terminal command presets.
- Migrate Docker data root between pools.

## User Framing

- For beginners, do not default to Docker terms unless they already asked from the Docker icon context.
- When a user came from App Store, prefer `znas-app-store` first.
- Use this skill when the user explicitly wants containers, images, networks, Compose projects, or Docker runtime settings.

## Safety Rules

1. Read `overview` and `config` before changing Docker runtime state.
2. Container/image/project delete actions require explicit confirmation.
3. Data-root migration is high risk; inspect current pool and explain impact first.
4. For logs stream routes, prefer short diagnostic use and avoid leaving a long-running command unattended.
5. Terminal commands in this CLI manage saved command presets; interactive websocket shell is a separate advanced path.
6. Never fall back to host-native `docker`, `docker compose`, `podman`, or daemon sockets/APIs when `znas docker ...` is available.
7. This prohibition applies to both remote control of another NAS and local unprivileged-agent control of the same NAS.
8. If `znas docker ...` cannot complete the task, report the limitation clearly and stop instead of trying the host runtime directly.

## Freshness Rules (Critical)

1. Docker overview, container/image/network/project lists, and logs are mutable runtime state.
2. For prompts about what is running now, how many containers/images/networks/projects exist now, or whether a project/container is still up, rerun the matching read command before answering.
3. If the user says they just started, stopped, deleted, recreated, or pulled something, treat previous runtime output as stale.
4. Earlier turns may provide the container name, project name, image name, or filters for the next query.
   - They do not replace the fresh read needed for the current answer

## Write Verification Rules (Critical)

1. Do not report Docker write success from the mutation response alone.
2. After delete, stop, start, restart, create, pull, or update operations, rerun the matching read command and verify the intended state before telling the user it succeeded.
3. If the follow-up read still shows the old resource or state, say the request was accepted but the final state is not yet confirmed.
4. If verification fails, say the latest state could not be verified instead of repeating stale output.

## Create Workflows

### Create Container From Image

1. Prefer the high-level workflow command: `znas docker create-from-image --image <repo:tag>` or `--image-id <id>`.
2. Let CLI do the fixed frontend-style steps internally:
   - resolve the exact local image
   - read `container recommend-config`
   - keep frontend default `environment_variables`, `network_settings`, `permissions`, `command_list`, and bridge `port_settings`
   - show candidate NAS paths collected from `znas file root spaces` plus `/personal` and `/teams`
3. When the command returns a plan without `--nas-path`, show the returned candidate paths to the user.
4. Do not turn Docker path picking into a storage-pool question.
5. Do not offer host-style examples like `/volume1/...` or `/pool_1/...`.
6. If the user wants a new folder, create it with `znas file root set-base-path` for top-level `/personal` or `/teams`, or `znas file folder create` for an existing concrete parent path, then rerun `znas docker create-from-image --nas-path <exact-physical-path>`.
7. `--nas-path` must be the exact physical `/zettos/pool/...` path returned by the NAS file picker, not a guessed `/zettos/pool/.../DATA` path and not a virtual `/teams/...` path.
8. Missing bridge `port_settings` or `port_type` can leave the container running but unreachable from the NAS IP, so do not strip the default networking block from the planned payload.
9. Verify with `container list` or `detail` before telling the user the container was created.

### Create Custom Compose Project

1. Use this flow when the user has YAML or wants a blank custom Docker item.
2. Ask for project `name` and show user-visible writable NAS paths for `compose_file_path`.
   - This is still a directory choice under `/personal` or `/teams`, not a storage-pool choice.
3. Use `znas docker project yaml-example` when the user wants a starter template.
4. If no existing directory fits, create one with `znas file` first, then use that exact path as `compose_file_path`.
5. Create with `znas docker project create --json '{"name":"<name>","compose_file_path":"<path>","docker_compose_file":"<yaml>","run_after_created":true}'`.
6. This is not the same as app-store `compose install`; do not switch to `install_pool` just because Docker data-root lives on another pool.
7. Verify with `project list` and affected `container list` output before reporting success.

## Delete Workflows

### Delete Container

1. Read the current container first with `znas docker container list --params '{"page":1,"page_size":100}'` and, if needed, `detail`.
2. Ask for explicit confirmation before deletion.
3. If the user also wants the image cleaned up, say clearly that the route only deletes the container and image cleanup is a second step.
4. Delete the container with `znas docker container delete --params '{"containerName":"<name>"}'`.
5. Verify the container is really gone by rerunning `container list` or `detail` before reporting success.
6. If the user confirmed image cleanup too, rerun `znas docker image local-list`, find the exact image artifact, then delete the image with full `--json` fields and verify it disappeared as well.

### Delete Image

1. Always read `znas docker image local-list --params '{"page":1,"page_size":100}'` first.
2. Match the exact local artifact by `repository + tag`, and include `image_id` when available.
3. Prefer `znas docker image delete --json '{"image_id":"<id>","image_name":"<repo>","tag":"<tag>","status":"<status>"}'`.
4. After delete returns, rerun `local-list` and confirm the image artifact is really gone before telling the user it was deleted.
5. If the artifact still exists, report that deletion was not yet confirmed and continue with a precise retry only after rereading the current artifact fields.

## Key Commands

```bash
znas docker overview get
znas docker config get
znas docker network list
znas docker container list --params '{"page":1,"page_size":100}'
znas docker create-from-image --image 'lscr.io/linuxserver/jackett:latest'
znas docker create-from-image --image-id '228bc266adfc'
znas docker create-from-image --image 'lscr.io/linuxserver/jackett:latest' --nas-path '/zettos/pool/1/teams/cjz/DATA/cjz/test'
znas docker container delete --params '{"containerName":"paperless-web"}'
znas docker image local-list --params '{"page":1,"page_size":100}'
znas docker image registry-list --params '{"search":"redis","page":1,"page_size":20}'
znas docker image pull --json '{"pull_type":"mirror_name","image_name":"busybox","tag":"latest"}'
znas docker image delete --json '{"image_id":"cd9176cd36f9","image_name":"busybox","tag":"latest","status":"uncreated"}'
znas docker project list --params '{"page":1,"page_size":100}'
znas docker project yaml-example
znas docker project create --json '{"name":"jackett-stack","compose_file_path":"/teams/docker-apps/jackett","docker_compose_file":"services:\n  jackett:\n    image: linuxserver/jackett:latest","run_after_created":true}'
znas docker terminal commands --params '{"container_id":"abc123"}'
```

Low-level create routes still exist below as backend surface, but image-to-container onboarding should prefer `znas docker create-from-image` instead of manually chaining `recommend-config` and `container create`.

## Features

### config

- `GET` `get` -> `/v2/docker/config` (auth)
- `PUT` `update` -> `/v2/docker/config` (auth)
- `POST` `set-proxy` -> `/v2/docker/proxy` (auth)
- `POST` `set-registry` -> `/v2/docker/registry` (auth)
- `POST` `set-accelerator` -> `/v2/docker/accelerator` (auth)

### container

- `GET` `list` -> `/v2/docker/containers` (auth)
- `GET` `detail` -> `/v2/docker/container/:containerName` (auth)
- `POST` `action` -> `/v2/docker/container/:containerName` (auth)
- `POST` `create` -> `/v2/docker/container` (auth)
- `DELETE` `delete` -> `/v2/docker/container/:containerName` (auth)
- `GET` `logs` -> `/v2/docker/container/logs` (auth)
- `POST` `stop-logs` -> `/v2/docker/container/logs/stop` (auth)
- `GET` `recommend-config` -> `/v2/docker/container/recommend_config` (auth)
- `PUT` `update` -> `/v2/docker/container/update` (auth)
- `POST` `metrics` -> `/v2/docker/containers/metrics` (auth)
- `GET` `logs-stream` -> `/v2/docker/container/:containerId/logs/stream` (auth)

### data-root

- `POST` `migrate` -> `/v2/docker/data_root/migrate` (auth)

### image

- `GET` `local-list` -> `/v2/docker/images` (auth)
- `POST` `pull` -> `/v2/docker/images` (auth)
- `POST` `load` -> `/v2/docker/images/load` (auth)
- `DELETE` `delete` -> `/v2/docker/image` (auth)
- `DELETE` `cancel-pull` -> `/v2/docker/image/cancel_pull` (auth)
- `POST` `export` -> `/v2/docker/image/export` (auth)
- `GET` `registry-list` -> `/v2/docker/registry/images` (auth)
- `GET` `versions` -> `/v2/docker/registry/images/versions` (auth)

### logs

- `GET` `list` -> `/v2/docker/logs` (auth)
- `DELETE` `delete` -> `/v2/docker/logs` (auth)

### network

- `GET` `list` -> `/v2/docker/network` (auth)
- `GET` `recommend-config` -> `/v2/docker/network/recommend_config` (auth)
- `POST` `create` -> `/v2/docker/network` (auth)
- `DELETE` `delete` -> `/v2/docker/network/:network_name` (auth)

### overview

- `GET` `get` -> `/v2/docker/overview` (auth)

### project

- `GET` `list` -> `/v2/docker/compose/projects` (auth)
- `GET` `detail` -> `/v2/docker/compose/project/:compose_project_name` (auth)
- `POST` `action` -> `/v2/docker/compose/project` (auth)
- `DELETE` `delete` -> `/v2/docker/compose/project` (auth)
- `POST` `create` -> `/v2/docker/compose/project/create` (auth)
- `POST` `recreate` -> `/v2/docker/compose/project/recreate` (auth)
- `GET` `logs` -> `/v2/docker/compose/project/:compose_project_name/logs/stream` (auth)
- `POST` `stop-logs` -> `/v2/docker/compose/project/logs/stop` (auth)
- `GET` `yaml-example` -> `/v2/docker/compose/project/create/recommend_config` (auth)
- `GET` `check-yaml` -> `/v2/docker/compose/project/check_yaml_file_exist` (auth)

### terminal

- `GET` `commands` -> `/v2/docker/terminal/commands` (auth)
- `POST` `add-command` -> `/v2/docker/terminal/commands` (auth)
- `DELETE` `delete-command` -> `/v2/docker/terminal/commands` (auth)
