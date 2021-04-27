> Development utilities for the PR:BF2 server.

## Server development

To easily launch a development server, you can use the following command:
```sh
> ./scripts/serve.sh path-to-server-folder
```
This runs the PR server in a docker container
By default the server listens for connections on `192.168.200.2:16567`.

## Baking a new version

### Setting up to run `prserverupdater`

To create a  baked server version, you will need the base server zip provided by the developers. You can download the server license zip from the [licence control panel](https://www.realitymod.com/forum/licensecp.php?do=downloads) on [realitymod.com](https://www.realitymod.com).

> I recommend that you place this file into the baker folder, but you can put it anywhere you want.

Next, `prserverupdater` requires a `license.key` file to work with when updating the server.
If you happen to have an already running server you can just copy this from the server folder.
Otherwise, you will have to create it in the root directory of the poject.
You can find your key on the [server license control panel](https://www.realitymod.com/forum/licensecp.php?do=info).

```sh
# Create the license file, and edit it to contain the license key.
> touch ./license.key
> vim license.key
# ... edit license.key to contain the key
```

### Baking a server version

Once everything is set up, you can then run the bake command, which will unzip the server into a temporary folder, run `prserverupdater` to get the latest server version and finally strip out any unnecessary files.

```sh
# Running the bake command
# Use your server IP and port associated with the license.
> ./scripts/bake.sh prbf2_1.6.3.0_server.zip 0.0.0.0 16567
```

> The IP and port doesn't have to be real or point to a valid server,
> it just has to match the ip on the license page.

> If you provide no port, the baker usees the default BF2 port `16567`.

The resulting server files will reside in `bakes/<starting_zip_name>_baked`.
Normally this folder is then copied to replace the server folder of the [server](https://gitlab.com/prboomers/server#readme) repository, and committed as a new base version.

### Cleaning up bakes

If you no longer need the baked files, or you want to clean up after a failed bake, run `./baking/clean`.
```sh
# Deleting all bakes and generated files
> ./scripts/clean.sh
```
