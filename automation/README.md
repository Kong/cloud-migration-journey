## Prequisiites

1. install deck - https://docs.konghq.com/deck/latest/installation/

2. terraform - https://learn.hashicorp.com/tutorials/terraform/install-cli

3. aws admin access ...

## Phase 1 Configuration

Create Konnect password file:

```console
konnect-password: {YOUR_PASSWORD}
konnect-email: {YOUR_EMAIL}
```

Copy file to your home dir:

```console
cp konnect-credentials $HOME/.deck.yaml
```

Validate connection to Konnect:

```console
deck ping --konnect-runtime-group-name default 
```

Push up deck configuration:

```console

```

Pull down deck configuration:

```console
deck dump --konnect-runtime-group-name default -o 1-kong.yaml
```
