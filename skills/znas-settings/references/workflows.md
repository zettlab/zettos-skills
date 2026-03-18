# Settings Workflows

## External share prerequisite

1. Read remote access state:
   - `znas settings remote p2p-status`
2. If disabled, enable it only after confirmation:
   - `znas settings remote set-p2p --json '{"enable":true}'`
3. Read device info to inspect current remote access ID:
   - `znas settings device info`
4. If needed, update the ID:
   - `znas settings device set-remote-id --json '{"remote_access_id":"my-office-2922"}'`

## User management

1. Read service status and public key first:
   - `znas settings user-auth status`
   - `znas settings user-auth public-key`
2. Read current users and groups before changing them:
   - `znas settings user list`
   - `znas settings group list`
3. For `user create`, pass plaintext password in `--json`; the CLI encrypts it automatically.
4. For `user edit`, only pass `password` when you intend to reset it.
5. Prefer create/delete of disposable test identities when validating the workflow.

## Teams folder permissions

1. For a specific teams folder in the Files permissions modal, read current share-folder permissions first:
   - `znas settings permission share-folder-get --params '{"path":"/zettos/pool/1/teams/demo/DATA/private"}'`
2. Use writable field `set_permission`, not computed field `action_permission`.
3. Preferred shorthand update:
   - `znas settings permission share-folder-update --json '{"path":"/zettos/pool/1/teams/demo/DATA/private","username":"jianzheng","set_permission":0}'`
4. CLI expands that shorthand into the full `group_permissions` payload expected by the backend.
5. For generic user/group ACL routes `permission set` and `permission update`, do not assume `action_permission` is writable.

## Local file-service inspection

1. Read the common service state:
   - `znas settings file-service info`
2. Read NFS/DLNA/rsync details before any change:
   - `znas settings nfs info`
   - `znas settings dlna info`
   - `znas settings rsync info`
3. Only then toggle or update service-specific settings.

## SMB / Bonjour / Time Machine workflow

1. Explain the goal in plain language first:
   - `SMB` is the main file-sharing protocol for Finder/Windows Explorer access.
   - `Bonjour` is the auto-discovery layer that helps Macs find the NAS in the network list.
   - `Time Machine folder` is the actual backup destination list, not just the discovery switch.
2. Read file-service state first:
   - `znas settings file-service info`
3. If SMB is disabled, enable it with the correct JSON body:
   - `znas settings file-service switch --json '{"enable_smb":true}'`
4. After enabling SMB, wait about 1 second and read back the state before claiming success:
   - `sleep 1 && znas settings file-service info`
5. Only use Bonjour path values `enable` or `disable`:
   - `znas settings bonjour switch --params '{"status":"enable"}'`
6. Do not guess alternate Bonjour values such as `on`, `open`, `true`, or `1`.
7. If the user wants real Time Machine backup, inspect or set the folder list too:
   - `znas settings timemachine folders`
   - `znas settings timemachine set-folders --json '{"sharePaths":["/teams/demo-backup"]}'`
8. Optional Time Machine params can be inspected after the switch:
   - `znas settings timemachine params`

## Certificate management

1. List certificates first:
   - `znas settings cert list`
2. For export or activation, always confirm the certificate `name`.
3. Upload/edit certificate files with multipart fields:
   - required upload fields: `cert.crt`, `cert_private.key`
   - optional fields: `intermediate_cert.crt`, `notes`
4. Prefer export and list before delete or regenerate actions.

## OTA, AI, and app-store operations

1. Read OTA schedule and firmware metadata before download or upgrade:
   - `znas settings update get-schedule`
   - `znas settings update current-version`
   - `znas settings update latest-version`
2. Read AI status before changing AI settings:
   - `znas settings ai-settings status`
3. Read installed apps for the target pool before any uninstall:
   - `znas settings app-store installed --params '{"pool_name":"pool_1"}'`
4. Treat OTA upgrade and app uninstall as confirmation-required actions.

## Safe time update

1. Read current time config:
   - `znas settings time get`
2. Read NTP list:
   - `znas settings time list-ntp`
3. Confirm timezone / sync mode with the user.
4. Write new config only after confirmation:
   - `znas settings time set --json '{"timezone":"Asia/Shanghai","isSynced":true,"timeServer":"pool.ntp.org","timeStr":"2026-03-10 12:00:00"}'`

## Network inspection before write

1. Read current interfaces:
   - `znas settings network list`
2. Check external connectivity:
   - `znas settings network check --params '{"domain":"quickconnect.zettlab.com"}'`
3. For static IP writes, verify the required fields before sending:
   - IPv4: `ipAddress`, `subnetMask`, `gateway`, `dns`
   - IPv6: `ipAddress`, `prefix`, `gateway`, `dns`

## Bridge creation guardrail

1. Read current interfaces:
   - `znas settings network list`
2. Count non-bridge NICs before creation:
   - normal bridge requires at least 2
   - virtual bridge requires at least 1
3. Only then create the bridge:
   - `znas settings network create-bridge --json '{"names":["LAN1","LAN2"]}'`

## Storage inspection before maintenance

1. Read storage-pool summary:
   - `znas settings storage-pool list`
2. Read physical disks:
   - `znas settings storage-pool disks`
3. Only after confirmation should you run pool repair, expansion, delete, or disk format routes.

## SMART inspection

1. Read disk inventory first:
   - `znas settings storage-pool disks`
2. Read the latest SMART report:
   - `znas settings smart info --params '{"device":"/dev/sdd"}'`
3. Only start or stop SMART tests after confirming the target disk and test type.
