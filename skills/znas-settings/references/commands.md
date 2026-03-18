# Settings Commands

## Device

```bash
znas settings device info
znas settings device set-name --json '{"name":"zettlab-office"}'
znas settings device refresh-remote-id
```

## System

```bash
znas settings system ready
znas settings system get-configs
znas settings system set-configs --json '{"language":"en-US"}'
```

## Remote

```bash
znas settings remote p2p-status
znas settings remote set-p2p --json '{"enable":true}'
znas settings remote support-status
znas settings remote set-support --json '{"hours":2}'
znas settings remote stop-support
```

## Users And Permissions

```bash
znas settings user-auth status
znas settings user-auth public-key
znas settings user list
znas settings user create --json '{"username":"demo_user","password":"Abcd1234!","role":"user","groups":[],"pools":[],"permissions":[]}'
znas settings group list
znas settings group create --json '{"group_name":"designers","users":[],"permissions":[]}'
znas settings permission get --params '{"name":"demo_user","identity_type":"user","paths":["/teams/demo"]}'
znas settings permission share-folder-get --params '{"path":"/zettos/pool/1/teams/demo/DATA/private"}'
znas settings permission share-folder-update --json '{"path":"/zettos/pool/1/teams/demo/DATA/private","username":"jianzheng","set_permission":0}'
```

## Local File Services

```bash
znas settings file-service info
znas settings file-service switch --json '{"enable_smb":true}'
znas settings nfs info
znas settings nfs add-dir --json '{"dirs":["/teams/demo"]}'
znas settings dlna info
znas settings dlna switch --json '{"enable_dlna":true}'
znas settings rsync info
znas settings rsync enable --json '{"username":"backup","passwd":"secret","port":873}'
znas settings bonjour switch --params '{"status":"enable"}'
znas settings timemachine folders
znas settings timemachine set-folders --json '{"sharePaths":["/teams/demo-backup"]}'
```

## Certificates

```bash
znas settings cert list
znas settings cert activate --params '{"name":"self-signed"}'
znas settings cert export --params '{"name":"self-signed"}' -o /tmp/certificate.zip
znas settings cert upload --form-file cert.crt=/tmp/cert.crt --form-file cert_private.key=/tmp/cert.key --form-text notes=office-cert
```

## OTA / AI / App Store

```bash
znas settings update get-schedule
znas settings update current-version
znas settings update latest-version
znas settings update set-schedule --json '{"frequency":7}'
znas settings ai-settings status
znas settings ai-settings set --json '{"enabled":true,"time_range_enabled":false,"start_time":"","end_time":""}'
znas settings app-store installed --params '{"pool_name":"pool_1"}'
```

## Network

```bash
znas settings network list
znas settings network check --params '{"domain":"quickconnect.zettlab.com"}'
znas settings network update --json '{"name":"LAN1","mode":"DHCP","dhcp":true,"manually":false,"isIPv6":false}'
znas settings network create-bridge --json '{"names":["LAN1","LAN2"]}'
znas settings network create-virtual-bridge --json '{"names":["LAN1"]}'
```

## Hardware

```bash
znas settings fan get
znas settings fan set-mode --params '{"fanType":0}'
znas settings light get
znas settings lcd get
znas settings ups get
znas settings ups switch --params '{"switch":true}'
```

## Storage

```bash
znas settings storage-pool list
znas settings storage-pool disks
znas settings storage-pool have
znas settings storage-pool delete --params '{"id":"pool1"}'
znas settings storage-pool available-info --json '{"pool_name":"pool1"}'
```

## SMART

```bash
znas settings smart info --params '{"device":"/dev/sdd"}'
znas settings smart status --params '{"device":"/dev/sdd"}'
znas settings smart start --params '{"device":"/dev/sdd","type":1}'
znas settings smart stop --params '{"device":"/dev/sdd"}'
```

## Time

```bash
znas settings time get
znas settings time list-ntp
znas settings time add-ntp --json '{"address":"pool.ntp.org"}'
znas settings time delete-ntp --json '{"address":"pool.ntp.org"}'
```
