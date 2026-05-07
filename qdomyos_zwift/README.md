# QDomyos-Zwift Home Assistant Add-on

> May not always be fully up to date with the mainline repo.

All credits go to [@cagnulein](https://github.com/cagnulein) and the
original [qdomyos-zwift](https://github.com/cagnulein/qdomyos-zwift) project. This is simply a Dockerfile wrapper to run
it as a Home Assistant add-on.

## Settings location

The add-on's configuration file is located at `/addon_configs/<id>_qdomyos-zwift/` in the Home Assistant file system.
Since the web interface can be slow it might be easier to edit the configuration on your phone and then copy it to the
add-on's config directory directly.

## Configuration

| Option          | Default | Description                                                                                                                       |
|-----------------|---------|-----------------------------------------------------------------------------------------------------------------------------------|
| `port`          | `8080`  | Port to access the Web UI                                                                                                         |
| `log_level`     | `info`  | Logging verbosity (`trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`)                                               |
| `no_gui`        | `false` | Run without the web UI (`-no-gui -no-console -no-log`). Useful for headless setups                                                |
| `lock_settings` | `true`  | Lock the settings file on startup so the app cannot overwrite it. Disable if you want the app to persist its own settings changes |
