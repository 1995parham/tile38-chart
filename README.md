# Tile38 Helm Chart

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/1995parham/tile38-chart/test.yaml?label=test&logo=github&style=for-the-badge&branch=main)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/1995parham/tile38-chart/release.yaml?label=release&logo=github&style=for-the-badge&branch=main)

## Introduction

Tile38 is an ultra-fast, in-memory geospatial database with native geofencing capabilities. It is designed for real-time location-based applications and supports complex spatial queries with very low latency.

This Helm chart deploys Tile38 on Kubernetes and supports a **leader–follower architecture** to enable horizontal read scaling while keeping write consistency.

### Architecture Overview

The chart deploys Tile38 using a **single leader** and **zero or more followers**:

* **Leader**

  * Handles all write operations
  * Acts as the source of truth
  * Can optionally persist data using a PersistentVolumeClaim (PVC)

* **Followers**

  * Replicate data from the leader
  * Serve read-only traffic for horizontal read scaling
  * Can be enabled or disabled via values
  * Replica count is configurable

Followers automatically connect to the leader using Tile38's native replication (`FOLLOW`) mechanism.

## Prerequisites

* Kubernetes **1.19+**
* Helm **3.0+**
* A working PersistentVolume provisioner (if persistence is enabled)
* Prometheus Operator (only if `serviceMonitor.enabled=true`)

---

## Installation and Quick Start

```bash
helm repo add tile38 https://1995parham.github.io/tile38-chart
helm repo update
helm install tile38 tile38/tile38
```

### Post-installation

After installation, Helm prints connection instructions in the output of `NOTES.txt`.

Example port-forwarding:

```bash
kubectl port-forward svc/tile38-leader 9851:9851
```

You can then connect using:

```bash
tile38-cli -p 9851 ping
```

---

## Configuration

Configuration values follow the structure of `values.yaml`.

### Image Parameters

| Name               | Description             | Default         |
| ------------------ | ----------------------- | --------------- |
| `image.repository` | Tile38 image repository | `tile38/tile38` |
| `image.tag`        | Image tag               | `latest`        |
| `image.pullPolicy` | Image pull policy       | `IfNotPresent`  |

### Leader Parameters

| Name                               | Description                           | Default     |
| ---------------------------------- | ------------------------------------- | ----------- |
| `leader.config.*`                  | Tile38 leader configuration           | `{}`        |
| `leader.service.type`              | Service type                          | `ClusterIP` |
| `leader.service.port`              | Service port                          | `9851`      |
| `leader.persistence.enabled`       | Enable persistence                    | `false`     |
| `leader.persistence.size`          | PVC size                              | `8Gi`       |
| `leader.persistence.storageClass`  | StorageClass name                     | `""`        |
| `leader.persistence.existingClaim` | Use existing PVC                      | `""`        |
| `leader.resources.*`               | Resource requests/limits              | `{}`        |
| `leader.extraFlags`                | Extra Tile38 flags                    | `[]`        |
| `leader.extraArgs`                 | Extra container args                  | `[]`        |

### Follower Parameters

| Name                            | Description                 | Default         |
| ------------------------------- | --------------------------- | --------------- |
| `followers.enabled`             | Enable follower replicas    | `false`         |
| `followers.replicaCount`        | Number of follower replicas | `1`             |
| `followers.config.follow_host`  | Leader service hostname     | `tile38-leader` |
| `followers.config.follow_port`  | Leader port                 | `9851`          |
| `followers.config.leaderauth`   | Leader auth password        | `""`            |
| `followers.config.read_only`    | Enable read-only mode       | `true`          |
| `followers.service.type`        | Service type                | `ClusterIP`     |
| `followers.service.port`        | Service port                | `9851`          |
| `followers.persistence.enabled` | Enable persistence          | `false`         |
| `followers.persistence.size`    | PVC size                    | `8Gi`           |
| `followers.resources.*`         | Resource requests/limits    | `{}`            |

### Global Parameters

| Name                        | Description                | Default |
| --------------------------- | -------------------------- | ------- |
| `global.podSecurityContext` | Pod-level security context | `{}`    |
| `global.securityContext`    | Container security context | `{}`    |
| `global.nodeSelector`       | Node selector              | `{}`    |
| `global.tolerations`        | Tolerations                | `[]`    |
| `global.affinity`           | Affinity rules             | `{}`    |

---

## Optional Features

### ServiceAccount

| Name                         | Description                | Default |
| ---------------------------- | -------------------------- | ------- |
| `serviceAccount.create`      | Create ServiceAccount      | `true`  |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}`    |
| `serviceAccount.name`        | Custom ServiceAccount name | `""`    |

Useful for integrating with cloud IAM roles (e.g., IRSA on AWS).

### Monitoring

| Name                     | Description           | Default |
| ------------------------ | --------------------- | ------- |
| `serviceMonitor.enabled` | Enable ServiceMonitor | `false` |

> Requires Prometheus Operator.

### Network Policy

| Name                    | Description             | Default |
| ----------------------- | ----------------------- | ------- |
| `networkPolicy.enabled` | Enable NetworkPolicy    | `false` |
| `networkPolicy.from`    | Allowed ingress sources | `[]`    |

Provides pod-level network isolation.

For advanced Tile38 configuration options, refer to:
[https://tile38.com/topics/configuration](https://tile38.com/topics/configuration)

---

## Operational Guidance

### Persistence

* **Leader** uses a single PVC when persistence is enabled
* **Followers** use StatefulSet `volumeClaimTemplates`, creating one PVC per replica

#### Existing Claims

You can attach an existing PVC to the leader using:

```yaml
leader:
  persistence:
    existingClaim: my-tile38-pvc
```

#### PVC Retention

If `persistence.keepOnDelete=true`, PVCs are retained after Helm uninstall.

### Verification

Run the included tests:

```bash
helm test tile38
```

Tests include:

* Connectivity test
* Follower replication test
* Geospatial operation test
* Set/Get validation

### Troubleshooting

* Validate connectivity:

```bash
tile38-cli ping
```

* Check replication status on followers:

```bash
tile38-cli server
```

### Uninstalling the Chart

```bash
helm uninstall tile38
```

> Note: PersistentVolumeClaims may remain depending on retention settings.

---

## License

This chart is licensed under the Apache 2.0 License.
