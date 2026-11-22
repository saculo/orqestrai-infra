# orqestrai-infra

How I host [orqestrai](https://github.com/saculo/orqestrai): a k3s cluster run by Argo CD from
this repository. orqestrai itself knows nothing of it; `orq serve` can as well run on a laptop.

```
bootstrap/          root.yaml (applied by hand, once) and the chart it deploys: the platform's
                    Applications, the image updates, and an ApplicationSet for apps/
platform/argocd/    Argo CD itself, with KSOPS and the Image Updater
platform/config/    the OpenBao store for External Secrets, the Tailscale login, network rules
                    (OpenBao, External Secrets and the Tailscale operator: upstream charts)
apps/<app>/         one folder per app, deployed as the Application <app> in the namespace <app>
                    apps/orq: orq serve, its state volume, its Service on the tailnet
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
  `ghcr.io/saculo/orqestrai` and commits each new `0.x` tag to `apps/orq/kustomization.yaml`
  (`imageUpdates` in [`bootstrap/values.yaml`](bootstrap/values.yaml)). `1.0.0` waits until the
  constraint there is changed by hand.
- **A new app** is a new folder in `apps/` (a kustomization); its image updates, if any, one
  line in `imageUpdates`.

## Working on it

```bash
git config core.hooksPath .githooks   # once: refuses a commit with a private value in plain text
sops apps/orq/orq.private.yaml             # edit a private file (needs the age key)
sops encrypt -i path/new.private.yaml # a new private file: no comments, SOPS leaves them readable
```

CI checks that every private file is encrypted, scans the history for secrets, and renders
the chart and Argo CD's kustomization.

The machine setup (k3s, Argo CD's first install, the age key, OpenBao's credentials) is not
here.
