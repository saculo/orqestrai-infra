# orqestrai-infra

How I host [orqestrai](https://github.com/saculo/orqestrai): a k3s cluster run by Argo CD from
this repository. orqestrai itself knows nothing of it; `orq serve` can as well run on a laptop.

```
apps/        the Argo CD Applications (a Helm chart; root.yaml points at it)
argocd/      Argo CD itself, with KSOPS and the Image Updater
platform/    the OpenBao store for External Secrets, the Tailscale login, network rules
orq/         orq serve: Deployment, database login from OpenBao, Service on the tailnet
```

- **Credentials** live in OpenBao, in the cluster. External Secrets copies each one into the
  Secret that needs it; nothing secret is in this repository.
- **Private values** (addresses, hostnames) are in `*.private.yaml` files, encrypted with
  [SOPS](https://getsops.io) and an age key: only the values under the keys in
  [`.sops.yaml`](.sops.yaml) are encrypted, the rest stays readable. Argo CD decrypts them
  with [KSOPS](https://github.com/viaduct-ai/kustomize-sops); the age private key is in the
  cluster's Secret `argocd/sops-age` and in my password manager, nowhere else.
- **New orq releases** deploy themselves: the
  [Image Updater](https://argocd-image-updater.readthedocs.io) watches
  `ghcr.io/saculo/orqestrai` and commits each new `0.x` tag to `orq/kustomization.yaml`
  ([`apps/templates/orq-image.yaml`](apps/templates/orq-image.yaml)). `1.0.0` waits until the
  constraint there is changed by hand.

## Working on it

```bash
git config core.hooksPath .githooks   # once: refuses a commit with a private value in plain text
sops orq/orq.private.yaml             # edit a private file (needs the age key)
sops encrypt -i path/new.private.yaml # a new private file: no comments, SOPS leaves them readable
```

CI checks that every private file is encrypted, scans the history for secrets, and renders
the chart and Argo CD's kustomization.

The machine setup (k3s, Argo CD's first install, the age key, OpenBao's credentials) is not
here.
