> Server baking utility for the PR:BF2 server.

This utility project helps preparing versions of the PRBF2 server by pre-applying the updates from `prserverupdater`.

## Baking a new version

### Setting up to run `prserverupdater`

To create a  baked server version, you will need the base server zip provided by the developers. You can download the server license zip from the [licence control panel](https://www.realitymod.com/forum/licensecp.php?do=downloads) on [realitymod.com](https://www.realitymod.com).

> I recommend that you place this file into the baker folder, but you can put it anywhere you want.

Next, `prserverupdater` requires a `license.key` file to work with when updating the server.
If you happen to have an already running server you can just copy this from the server folder.
Otherwise, you will have to create it in the root directory of the poject.

```sh
# Create the license file from your key
# see: https://www.realitymod.com/forum/licensecp.php?do=info
> printf "MY-SERVER-LICENSE-KEY" > ./license.key
```

### Baking a server version

Once everything is set up, you can then run the bake command, which will
- unzip the server into a temporary folder,
- run `prserverupdater`
- and finally, strip out any unnecessary `.exe` and `.dll` files.

```sh
# Running the bake command
# Substitute your server IP and port associated with the license.
# The IP and port doesn't have to be real or point to a valid server,
# it just has to match the ip on the license page.
> ./bake prbf2_1.6.3.0_server.zip 0.0.0.0 16567
```

> If you provide no port, it usees the default BF2 port `16567`.

The resulting server files will reside in `bakes/<starting_zip_name>_baked`.
Normally this folder is then copied to replace the server folder of the [server](https://gitlab.com/prboomers/server#readme) repository, and committed as a new base version.

### Cleaning up bakes

If you no longer need the baked files, or you want to clean up after a failed bake, run `./baking/clean`.
```sh
# Deleting all bakes
> ./clean
```
**Beware, this will indiscriminately remove everything in `./bakes`!**
