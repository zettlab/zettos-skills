---
name: znas-app-store
description: "Call Zettos App Store APIs for app catalog, compose app install/update/status, and app-store settings."
---

# znas app-store

> Use this skill when the user wants to browse NAS apps, install or update an app, start/stop an installed app, read app-store settings, or manage Zettlab apps from an app-centric perspective.

## What This Skill Is For

- Browse what apps are available or already installed.
- Read or change the default app install pool.
- Read compose-app details.
- Install a compose app from YAML.
- Update, start, stop, cancel-install, or uninstall a compose app.
- Install or uninstall Zettlab-branded apps such as Docker from the app-store side.

## User Framing

For beginners, explain App Store as:
- `给 NAS 装软件和管理软件的地方`
- Mention `Docker/Compose` only if the user needs the technical detail.
- Prefer the app-centric wording: install app, update app, stop app, uninstall app.

## Safety Rules

1. Read app state before changing it.
2. For compose app install, send the real install request directly; do not use `dry_run=true` on this backend.
3. Confirm before uninstall/update/install unless the user explicitly asked for the action.
4. Read the default install pool before changing it.
5. For compose app detail, you can request YAML by adding `--header accept=application/yaml`.
6. Do not bypass `znas app-store ...` with native `docker`, `docker compose`, `podman`, or direct internal HTTP calls.
7. If an app-store route is missing or fails, report the limitation instead of falling back to host-native runtime commands.

8. `install_pool` is a NAS storage-pool name such as `pool_1`, not an arbitrary filesystem path.
9. Ask the user which storage pool to install into unless they already gave a standing install-pool preference.
10. Treat `znas app-store settings default-pool` as reference only; do not silently use it as the install target unless the user explicitly said to keep using that pool.
11. Do not send `dry_run=true` for `app-store compose install`; CLI should send the real install request with `dry_run=false`.
12. If the user gives a made-up path or non-existent pool, reject it and explain the valid pool choices first.

## Workflow Boundary (Critical)

1. Default app install flow: check `znas app-store app list --params '{"only_installed":false}'` first.
2. If the target app exists in the store catalog, stay on the app-store path.
3. If the target app exists in the store catalog and the user wants to install it, ask which `install_pool` to use before `compose install` unless they already set a standing pool preference.
4. If the target app is missing from the catalog, do not invent an app-store compose install flow.
5. Missing catalog app => switch to `znas docker ...`:
   - single-image app: use `znas docker create-from-image --image <repo:tag>` to let CLI resolve the image, read recommend-config, keep default env/network/port sections, and show NAS folder candidates
   - custom compose/yaml app: `project yaml-example` or user YAML -> user chooses `compose_file_path` -> `project create`
6. `app-store compose install` is for store-provided compose apps, not generic third-party Docker onboarding.

## Freshness Rules (Critical)

1. Installed apps, app counts, compose status, default pool, and browser-openable URLs are mutable state.
2. When the user asks `现在装了哪些应用`, `还有几个应用`, `默认装到哪个池`, `现在这个应用好了没`, or any equivalent current-state question, rerun the relevant read command before answering.
3. After install, update, start, stop, cancel, or uninstall, always re-query installed and runtime state before claiming the latest result.
4. A prior turn may identify the target app or pool.
   - It does not make the old installed/status result reusable as the current truth

## After Install Or Start (Mandatory)

If the app can be opened in a browser (`open_in_browser=true`), do not stop at `installation enqueued` or `container running`.

Async install state handling:
- `installation enqueued` means the request was accepted, not that the app is installed yet.
- app-store status `install` means the app is still in the async installation pipeline.
- app-store status `waiting` means the task is queued; `installing` means the worker has started it.
- if install returns conflict or any ambiguous error, rerun `app list` immediately; if the app now shows `waiting` or `installing`, do not submit install again.
- Do not translate `install` into a specific root cause such as `正在下载镜像` unless you have direct evidence from image/project/container state or backend logs.
- Do not claim `network/Docker Hub/registry is broken` unless you have explicit failure evidence.

1. Read the installed-app metadata and confirm the app is actually present.
2. Read the runtime/container status and confirm the main app container is running.
3. Build a user-usable URL from `scheme + host + port_map + index`.
4. Host selection rule:
   - if the active login/base URL host is a real reachable NAS host, reuse that host
   - if the active login/base URL is `localhost` or `127.0.0.1`, resolve a connected NAS IPv4 via `znas settings network list` and use that IP instead
5. Verify the URL before sending it to the user.
   - for local HTTP verification with shell tools, unset `http_proxy`, `https_proxy`, and `all_proxy` first
6. If the app metadata or docs expose default credentials, include them in the reply.
7. If no default credentials are exposed, explicitly say the app requires first-run setup instead of inventing a username/password.

Recommended install verification sequence:
1. `znas app-store app list --params '{"only_installed":false}'` to read catalog/store status.
2. If the target app now shows `waiting` or `installing`, report that state and stop retrying `compose install`.
3. `znas app-store compose installed --params '{"pool_name":"pool_1"}'` to see if the app has entered the installed compose-app set.
4. `znas app-store compose detail --params '{"id":"<app-id>"}'` only after the app exists as an installed compose app.
5. `znas docker project list --params '{"page":1,"page_size":100}'` and `znas docker container list --params '{"page":1,"page_size":100}'` to confirm runtime state.
6. If the app is still `install` and runtime state has not appeared yet, report it as `still installing / pending backend completion`, not as success or as a guessed root cause.

## Key Commands

```bash
znas app-store app list --params '{"only_installed":false}'
znas app-store settings default-pool
znas app-store compose installed --params '{"pool_name":"pool_1"}'
znas app-store compose detail --params '{"id":"paperless"}'
znas app-store compose detail --params '{"id":"paperless"}' --header accept=application/yaml -o paperless.yml
znas app-store compose install --params '{"install_pool":"pool_1","check_port_conflict":true}' --body-file ./paperless.yml --content-type application/yaml
znas app-store compose install --params '{"install_pool":"not_a_pool","check_port_conflict":true}' --body-file ./paperless.yml --content-type application/yaml  # should fail: invalid pool
znas app-store compose status --params '{"id":"paperless"}' --json '{"status":"stop"}'
znas app-store compose update --params '{"id":"paperless"}'
znas app-store compose uninstall --params '{"id":"paperless"}'
```

## Features

### app

- `GET` `list` -> `/v2/app_management/apps` (auth)
- `GET` `grid` -> `/v2/app_management/web/appgrid` (auth)
- `GET` `yaml` -> `/v2/app_management/apps/:id/compose` (auth)

### compose

- `GET` `installed` -> `/v2/app_management/apps/installed` (auth)
- `GET` `detail` -> `/v2/app_management/compose/:id` (auth)
- `POST` `install` -> `/v2/app_management/compose` (auth)
- `PUT` `apply-settings` -> `/v2/app_management/compose/:id` (auth)
- `PATCH` `update` -> `/v2/app_management/compose/:id` (auth)
- `PUT` `status` -> `/v2/app_management/compose/:id/status` (auth)
- `DELETE` `cancel-install` -> `/v2/app_management/compose/:id/cancel_install` (auth)
- `DELETE` `uninstall` -> `/v2/app_management/compose/:id` (auth)

### settings

- `GET` `get` -> `/v2/app_management/settings` (auth)
- `PUT` `set` -> `/v2/app_management/settings` (auth)
- `GET` `default-pool` -> `/v2/app_management/default_install_pool` (auth)
- `PUT` `set-default-pool` -> `/v2/app_management/default_install_pool` (auth)

### zettlab

- `POST` `install` -> `/v2/app_management/install/zettlab_app` (auth)
- `DELETE` `uninstall` -> `/v2/app_management/uninstall/zettlab_app` (auth)
