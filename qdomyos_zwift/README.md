# QDomyos-Zwift Home Assistant Add-on

> May not always be fully up to date with the mainline repo.

> **Note:** Connecting to Bluetooth accessories (e.g. Zwift Play controllers) appears to be broken at the moment and may
> not work as expected.

All credits go to [@cagnulein](https://github.com/cagnulein) and the
original [qdomyos-zwift](https://github.com/cagnulein/qdomyos-zwift) project. This is simply a Dockerfile wrapper to run
it as a Home Assistant add-on.

## Settings

The add-on's configuration file (`qDomyos-Zwift.conf`) is located at `/addon_configs/<id>_qdomyos_zwift/` in the Home
Assistant file system. Logs are available under `/addon_configs/<id>_qdomyos_zwift/logs/`.

## Configuration

| Option          | Default | Description                                                                   |
|-----------------|---------|-------------------------------------------------------------------------------|
| `port`          | `8080`  | Port to access the Web UI                                                     |
| `no_gui`        | `false` | Run headless (`-no-gui -no-console -no-log`). Useful if the GUI causes issues |
| `mqtt_host`     | `""`    | MQTT broker host. Leave empty to disable MQTT                                 |
| `mqtt_port`     | `1883`  | MQTT broker port                                                              |
| `mqtt_username` | `""`    | MQTT username                                                                 |
| `mqtt_password` | `""`    | MQTT password                                                                 |
| `mqtt_deviceid` | `""`    | MQTT device ID                                                                |
