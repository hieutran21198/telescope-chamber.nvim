# Telescope Chamber

Telescope Chamber is a plugin that supported chamber tool for storing secrets.

## Prerequisites:

- [AWS CLI version >= 2](https://aws.amazon.com/cli)
- [Chamber CLI](https://github.com/segmentio/chamber)
- [Telescope Plugin](https://github.com/nvim-telescope/telescope.nvim)

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
- ...
