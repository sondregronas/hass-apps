# QDomyos-Zwift Home Assistant Add-on

> May not always be fully up to date with the mainline repo.

> **Note:** Bluetooth accessory support (e.g. Zwift Play controllers) didn't work reliably for me in this addon — the
> official app works great though. Your mileage may vary.

All credits go to [@cagnulein](https://github.com/cagnulein) and the
original [qdomyos-zwift](https://github.com/cagnulein/qdomyos-zwift) project. This is simply a Dockerfile wrapper to run
it as a Home Assistant add-on.

## Settings

The add-on's configuration file (`qDomyos-Zwift.conf`) is located at `/addon_configs/<id>_qdomyos_zwift/` in the Home
Assistant file system.

## Configuration

| Option          | Default | Description                                                                   |
|-----------------|---------|-------------------------------------------------------------------------------|
| `port`          | `8080`  | Port to access the Web UI                                                     |
| `no_gui`        | `false` | Run headless (`-no-gui -no-console -no-log`). Useful if the GUI causes issues |
| `mqtt_host`     | `""`    | *(optional)* MQTT broker host                                                 |
| `mqtt_port`     | `1883`  | *(optional)* MQTT broker port                                                 |
| `mqtt_username` | `""`    | *(optional)* MQTT username                                                    |
| `mqtt_password` | `""`    | *(optional)* MQTT password                                                    |
| `mqtt_deviceid` | `""`    | *(optional)* MQTT device ID                                                   |
