# 1password-cli

## TL;DR

```shell
# installation
brew cask install 1password-cli

# first login
op signin company.1password.com user.name@company.com
# subsequent logins
op signin company

# automatically set environment variables
# needed to run the export command manually
eval $(op signin company)

# show all the items in the account
op list items
```

## Gotchas

- After you have signed in the first time, you can sign in again using your account shorthand, which is your sign-in address subdomain (in this example, _company_); `op signin` will prompt you for your password and output a command that can save your session token to an environment variable:

  ```shell
  op signin company
  ```

- Session tokens expire after 30 minutes of inactivity, after which you'll need to sign in again

## Further readings

- [CLI guide]

[cli guide]: https://support.1password.com/command-line/

## Sources

- [CLI getting started] guide

[cli getting started]: https://support.1password.com/command-line-getting-started/
