# Telescope Chamber

Chamber plugin for `neovim`

## Configuration

Default configuration of `telescope-chamber`.

```lua
local options = {
  -- another options here
	extensions = {
		["chamber"] = {
			aws = {
				profile = "default",
				region = "ap-southeast-1",
				service = "",
			},
			-- if use_cached_profiles == true, list profiles and regions will be
			-- loaded at setup scenerio instead.
			use_cached_profiles = false,
      -- if load_from_env == true, it will load profiles and regions from
      -- environment and override the opts.aws.profile & opts.aws.region
      -- configuration.
			load_from_env = false,
		},
	},
}

telescope.setup(options)
```

## Pickers

Some simple pickers that make life of developer to be easier.

| Name       | Command                      | Description                                 |
| ---------- | ---------------------------- | ------------------------------------------- |
| `profiles` | `Telescope chamber profiles` | Set AWS profile                             |
| `regions`  | `Telescope chamber regions`  | Set AWS regions                             |
| `services` | `Telescope chamber services` | Set service and get key=value from service. |

## To do:

- [x] Set AWS profiles & regions.
- [x] Render list of services and get `key=value` inside.
- [ ] Asynchronous to load profiles and regions on setup.
- [ ] Support `AWS_VAULT`.
- [ ] Write contents to file.
- [ ] Read content file, show changes and update to chamber.
