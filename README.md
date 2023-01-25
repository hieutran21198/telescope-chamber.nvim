# Telescope Chamber

Telescope Chamber is a plugin that supported chamber tool for storing secrets.

## Prerequisites

- [AWS CLI version >= 2](https://aws.amazon.com/cli)
- [Chamber CLI](https://github.com/segmentio/chamber)
- [Telescope Plugin](https://github.com/nvim-telescope/telescope.nvim)

## Setup

### `Lazy` Package management

Put `hieutran21198/telescope-chamber` into list of dependencies of telescope.

### Config

Here is the default options of this plugin.

```lua
local default_opts = {
	aws = {
		profile = "default",
		region = "us-east-1",
		service = "",
	},
	mappings = {
		confirm = {
			mode = "i",
			key = "<CR>",
		},
		save = {
			mode = "i",
			key = "<C-s>",
		},
		save_to_file = {
			mode = "i",
			key = "<C-S>",
		},
		re_select_profile = {
			mode = "i",
			key = "<C-r>",
		},
		pull_variables = {
			mode = "i",
			key = "<C-p>",
		},
		push_to_chamber = {
			mode = "i",
			key = "<C-P>",
		},
	},
	allow_env = true,
}
```

Passed your options into telescope `extensions` option field.

```lua
local chamber_opts = {
  -- ...
}

local telescope_opts = {
    -- ...
    extensions = {
        chamber = chamber_opts,
    },
    -- ...
  }
local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end

telescope.setup(telescope_opts)
```

## Commands

| Command                             | Description                                  |
| ----------------------------------- | -------------------------------------------- |
| telescope.extension.chamber.region  | select one of supported regions              |
| telescope.extension.chamber.profile | select an AWS profile                        |
| telescope.extension.chamber.service | select an AWS service to get list of secrets |
| telescope.extension.chamber.secret  | select a secret and append to current line   |

## To-dos

- [x] Get secret of a service by profile and region.
- [x] Write secrets of a service to a file.
- [ ] Support AWS Vault for authenticating.
- [ ] Edit and compare local & remote secrets.
      ...

## `Which-key` plugin

```lua
-- whichkey
{
  c = {
    name = " Chamber",
    p = {
      function()
        local telescope = require "telescope"
        telescope.extensions.chamber.profile {
          pick_region = true,
          pick_region_opts = {},
        }
      end,
      "ףּ Set profile and region",
    },
    P = {
      function()
        local telescope = require "telescope"
        telescope.extensions.chamber.profile {
          pick_region = false,
        }
      end,
      "ףּ Set profile with default region",
    },
    s = {
      function()
        local telescope = require "telescope"
        telescope.extensions.chamber.service {}
      end,
      "∑ Get service's secrets",
    },
    v = {
      function()
        local telescope = require "telescope"
        telescope.extensions.chamber.secret {}
      end,
      "ϖ Get secret value",
    },
  }
}
```
