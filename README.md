# 7 Days to Die Server

## Environment Variables

| Variable  | Description                                                       |
|-----------|-------------------------------------------------------------------|
| `VERSION` | Sets the game version that will be installed. (default: `stable`) |

Most variables in `serverconfig.xml` can be set using their upper snake-case form, 
e.g. to set `ServerName` in `serverconfig.xml`, use the `SERVER_NAME` environment variable.

## Persistence

| Directory | Description                                          |
|-----------|------------------------------------------------------|
| `/data`   | Saves, worlds and mods are stored in this directory. |
| `/server` | The games server is installed in this directory.     |
