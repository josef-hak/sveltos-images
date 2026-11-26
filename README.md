# Sveltos container images

Independent builds of the [Project Sveltos](https://github.com/projectsveltos)
images that [k0rdent KCM](https://github.com/k0rdent/kcm) pulls, so KCM can run
on images we built from sources we hold, instead of on `docker.io/projectsveltos`.

Target version: **v1.17.0** (`VERSION`) -- the appVersion of the
`projectsveltos` chart KCM 1.17.1 depends on.

Images are published as `ghcr.io/josef-hak/projectsveltos/<name>:<version>`,
publicly pullable, built and pushed by `.github/workflows/images.yml`. The
name after the last `/` is kept identical to upstream's, so pointing the chart
at the registry is a one-value change and nothing else has to be renamed.

A KCM 1.14.0-dev install runs its whole sveltos stack on these images and
passes all 13 ksm-tests scenarios -- see `notes/v1.17.0-test.md`.

## What can and cannot be built

Eleven of the images the chart and its controllers reference have public
sources; five do not -- `github.com/projectsveltos/<name>` returns 404 for them.

| image | source | in this repo |
| --- | --- | --- |
| addon-controller | public | `src/addon-controller` |
| classifier | public | `src/classifier` |
| event-manager | public | `src/event-manager` |
| healthcheck-manager | public | `src/healthcheck-manager` |
| sveltoscluster-manager | public | `src/sveltoscluster-manager` |
| access-manager | public | `src/access-manager` |
| shard-controller | public | `src/shard-controller` |
| crd-manager | public | `src/crd-manager` |
| register-mgmt-cluster | public | `src/register-mgmt-cluster` |
| clusterinventory-controller | public | `src/clusterinventory-controller` |
| sveltosctl | public | `src/sveltosctl` |
| **sveltos-agent** | **no public repo** | -- |
| **drift-detection-manager** | **no public repo** | -- |
| **techsupport** | **no public repo** | -- |
| **mcp-server** | **no public repo** | -- |
| **sveltos-applier** | **no public repo** | -- |

The five without sources are not all equal in how much they block a build of
our own:

- `techsupport` and `mcp-server` are optional chart components. KCM already
  disables both (`templates/provider/projectsveltos/values.yaml`), so nothing
  pulls them.
- `sveltos-applier` only runs in pull mode, which KCM does not use.
- `sveltos-agent` and `drift-detection-manager` are the ones that matter.
  Neither is a Deployment in the chart: `classifier-manager` and
  `addon-controller` create them inside each managed cluster at run time, from
  an image name their own code holds. A cluster under KCM therefore still runs
  two upstream images, and no value in this repo changes that.

Deployment names differ from image names in a few places -- `classifier-manager`
runs `projectsveltos/classifier`, `hc-manager` runs
`projectsveltos/healthcheck-manager`, `sc-manager` runs
`projectsveltos/sveltoscluster-manager`, and `sveltos-agent-manager` is the
agent Deployment the classifier creates, not a chart component.

## Layout

```
components.env      dir|upstream repo|image name, one line per image
VERSION             the tag every source is vendored at and every image tagged with
src/<dir>/          upstream working tree at that tag, plus a SOURCE file
                    recording the exact commit; .git and doc/ pruned
scripts/vendor.sh   (re-)fetch sources at VERSION
scripts/build.sh    docker build from the vendored tree
scripts/push.sh     docker push
```

Sources are vendored rather than cloned at build time: the build then depends
on this repo alone, and `src/*/SOURCE` says exactly which upstream commit each
tree came from.

The build calls `docker build` directly instead of upstream's
`make docker-build`, which additionally runs `go generate` and rewrites
manifests in its own tree -- neither is an input to the image, and skipping
them means a build needs no Go toolchain on the host.

## Use

Publishing is CI's job and only CI's -- `.github/workflows/images.yml` builds
each component in its own runner and pushes with the job token. Locally you
vendor and build; you do not push.

```sh
bash scripts/vendor.sh                 # all, or name components to limit
bash scripts/build.sh                  # builds into the local docker daemon

VERSION=v1.18.0 bash scripts/vendor.sh # bump: re-vendor, commit, let CI publish
REGISTRY=my.registry/ns bash scripts/build.sh
```

A push to `main` that touches `src/`, `VERSION`, `components.env` or
`scripts/` rebuilds and republishes everything. To rebuild without a commit,
or to redo one component, run the workflow by hand:

```sh
gh workflow run images.yml                      # all of them
gh workflow run images.yml -f components=classifier
```

## Using them in KCM

`kcm/values-ghcr.yaml` is the provider config that points the chart at this
registry, and `kcm/verify.sh` reports which registry a cluster's sveltos pods
actually came from.

With [ksm-tests](https://github.com/k0rdent/ksm-tests):

```sh
cd ../ksm-tests
eval "$(./scripts/kcm_default.sh --export)"
export SVELTOS_VALUES="$HOME/sveltos-images/kcm/values-ghcr.yaml"
export SVELTOS_SCALE_ZERO=""     # keep every component up, so each image runs
./scripts/deploy_k0rdent.sh
KUBECONFIG=./kcfg_k0rdent bash ../sveltos-images/kcm/verify.sh
```

A cluster can also be fed straight from the local docker daemon, which is how
an unpublished build gets tested before it is on GHCR -- the chart sets no
`imagePullPolicy` and the tag is not `latest`, so `IfNotPresent` applies and a
preloaded image is never pulled:

```sh
for i in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep projectsveltos/); do
    docker save "$i" | docker exec -i k0rdent-<KCM> k0s ctr -n k8s.io images import --platform linux/amd64 -
done
```
