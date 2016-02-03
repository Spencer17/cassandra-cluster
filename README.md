# Cassandra cluster (EXPERIMENTAL)

This `cassandra-cluster-experimental` template and its associated images allow deploying an ephemeral Cassandra 2.2 cluster on top of Kubernetes/OpenShift.

At this cluster, all the nodes are seeds and are dynamically discovered by means of a Kubernetes service and a custom seed provider (look at [seed discovery advanced topic](#seed-discovery) for details).

It is based on the [Cassandra Kubernetes example](https://github.com/kubernetes/kubernetes/tree/master/examples/cassandra) but has some very important improvements:

- Cassandra version bumped to 2.2
- Debian base image version bumped to Jessie (Docker Hub version)
- Cassandra pods can be configured so that they self-decomission while they are killed.
- Kubernetes example did not properly forward signals to the `cassandra` process, as it is a child of the `run.sh` script (`exec` is not used). We now do at our `run.sh`.
- At the Kubernetes example, `cassandra-env.sh` calculated memory limits based on the memory of the whole node (by using the `free` command). We provide a modified version that calculates these limits from information provided by `cgroups`, i.e. the actual memory limits of the container.
- Docker build can be triggered behind a proxy (with docker build-args).
- OpenShift templates are provided to easily deploy this Cassandra cluster.

## Before using the template in a project

Before using this template and/or its associated images in a project, a service account called `cassandra` **must previously exist** in that project and have **read** permissions. This is required so that seed discovery can be properly performed (look at [seed discovery advanced topic](#seed-discovery) for details).

In order to create such a service account and give it read permissions, a **project admin** must do the following:
1. Copy this into a new file, for instance, `cassandra-sa.yml`:
   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: cassandra
   ```
2. Then, run `oc create -f cassandra-sa.yml` on your project. So, you will have your service account created.
3. Run `oc policy add-role-to-user read system:serviceaccount:YOUR_PROJECT:cassandra` (where `YOUR_PROJECT` must be the name of your project). Doing that, you will give edit permissions to the service account.

## Deploy a standalone Cassandra

Just follow the steps for a Cassandra cluster, described below, and keep it with one replica (do not worry, it is very easy).

## Deploy a Cassandra cluster

In order to deploy a Cassandra cluster, just create a new `cassandra-cluster-experimental` from the template. Parameters are:

- Application name (`APP_NAME`): The name of your cluster.
- Pod max memory (`POD_MAX_MEM`): Maximum memory for each pod (in Megabytes). Note that this is the total limit of the memory Pod. Once we provide that limit to Cassandra default startup process, it properly tunes Java heap to achieve best performance (more information [here](http://docs.datastax.com/en/cassandra/2.2/cassandra/operations/opsTuneJVM.html?scroll=opsTuneJVM__tuning-the-java-heap)).

Once created, you will get the following:

- A `Service` pointing to all your Cassandra nodes (remember that all of them are seeds). It only exposes CQL port `9042`
- A `ReplicationController` that manages all your Cassandra replicas, allowing up and down scaling.

Note that, due to some Cassandra restrictions, we are directly using a Kubernetes `ReplicationController` instead of an OpenShift `DeploymentConfig` (which uses `ReplicationController` objects under the hood). **This has some important implications**:

- You may be used to run many commands like `oc scale dc <myApp>`, `oc get dc <myApp>`, `oc describe dc <myApp>`, `oc edit dc <myApp>`... These commands are for deployment configs. Instead, you must use the ones for replication controllers, just by replacing `dc` with `rc`: `oc scale rc <myApp>`, `oc get rc <myApp>`, `oc describe rc <myApp>`, `oc edit rc <myApp>`...
- Commands specifically related to OpenShift deployments will not work at all. These include (but are not limited to): `oc deploy`, `oc rollback`...

## Scale the cluster

If you want to scale up or down your Cassandra cluster, just scale up and down the created `ReplicationController` as usual with: `oc scale rc <myApp> --replicas=<NReplicas>` (where `<myApp>` is the name of your application and `<NReplicas>` is the new number of replicas).

> Note: When scaling down, nodes are automatically decommissioned before shutting them down. Thus, you may need up to 180 seconds (3 minutes) so that a node completely disappears while scaling down.

## Building

Just run `./build.sh` script with the following syntax:

```
Usage: ./build.sh [--clean] <imageTag> [<dockerBuildArg1> <dockerBuildArg2> ...]
```

Where:

- `--clean` indicates whether we want to clean or not (not cleaning = build).
- `imageTag` indicates the tag for the Cassandra Docker image.
- `dockerBuildArgN` are build-args for the Docker image. These ones are allowed:
  - `http_proxy`: An HTTP proxy to be used inside building intermediate containers
  - `https_proxy`: An HTTPS proxy to be used inside building intermediate containers
  - `no_proxy`: A list of hosts that must not use the proxy

This scripts can do two things: build or clean. While building, it just:

- Compiles the Java project with the Kubernetes seed provider.
- Copies the JAR to the image directory
- Builds the Docker image via `docker build`


**IMPORTANT:** After building, you **must** edit all the files inside openshift subdirectory and replace `docker.io/produban/cassandra-cluster:latest` with the tag specified at `<imageTag>`. Otherwise, it may not work.


While cleaning:

- Cleans the Java Maven project
- Removes the image with the provided tag

## Advanced topics

### Seed discovery

Pods may be dynamically generated with random IPs, so we cannot rely on a fixed seed list as usual in classic Cassandra deployments. Instead, we use the following:

- A Kubernetes `Service` that maintains an endpoint list of all the Cassandra replicas.
- A custom Cassandra `SeedProvider` that reads endpoints from that service and provides them as seeds (this is what requires the `cassandra` service account with read permissions).

The custom seed provider source code can be found at `java/` subfolder. It is a Maven project containing a simple class implementing `org.apache.cassandra.locator.SeedProvider` interface, getting the desired behavior.

While building this project, a `target/kubernetes-cassandra.jar` file is generated. Then, it should be included in the image (`image/` subdirectory). Our image makes this JAR available at Cassandra classpath and its `cassandra.yaml` configuration file chooses it as the default seed provider.
