# Codefresh PR demo

A recipe for automating GitHub Pull Request release CI pipelines with Kubernetes, Helm and Codefresh.

## Container registry, K8S cluster, and Helm

Although Codefresh can connect to other K8S cloud providers and container registries, for simplicity, this tutorial assumes a functioning GKE K8S cluster and GCR registry.

1. In [cloud console](https://console.cloud.google.com), note the GCP project name associated with your GKE cluster for use farther below.
1. Create a new namespace if you don't have one you want to use for this demo. I recommend `kubectl create ns codefresh`, but the `NAMESPACE` environment variable required by this demo app is configurable.
1. Helm must be installed, and you must be able to connect to Tiller to your desired namespace. The simplest way to secure your Tiller installation is the first approach (restart tiller with `--listen=localhost:44134` flag) outlined in [this excellent article](https://engineering.bitnami.com/articles/helm-security.html) by @anguslees. If you take a more complicated approach, this tutorial assumes you know what you're doing.

## Set up a GitHub repo for a Codefresh pipeline

In GitHub UI:

1. Fork this repo
1. Create and save a new [GitHub Personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/), setting the `repo` scope

## Connect your Codefresh repository

In Codefresh UI:

1. Create a [Codefresh account](https://docs.codefresh.io/docs/create-an-account) with a GitHub user, if you haven't alrady done so. Note this demo is for GitHub - if you already have a Codefresh account connected to another git provider:
    > Currently, it is possible to have only one git provider per account. You have to create a separate Codefresh account for each of your git providers.

    Be sure to accept the permission request for Codefresh to access your git provider account.
1. Add your fork of this repo as a [(GitHub) repository](https://docs.codefresh.io/docs/getting-started-create-a-basic-pipeline)
1. Create and save a new [Codefresh API key](https://g.codefresh.io/account/tokens)

## Configure a PR action filter pipeline

You will create two pipelines. This first pipeline will filter PR actions to only those you wish to trigger a Pull Request release: if the actions are one of "opened", "reopened", "synchronize", or "closed", this will trigger the second pipeline responsible for building the PR release. Note that a future feature of Codefresh - allowing selection of Pull Request actions to trigger a build - will make this first step unnecessary.

1. Name your first pipeline "PR action filter"
1. Under `Configuration` > `General Settings` > `Automated build`:
    1. `Trigger flow on` select `All Branches and Tags`
    1. `Add webhook` toggle `On`
    1. `Trigger by` select only `Pull request opened`
1. Under `Configuration` > `Environment Variables` fill out the `New variable` key and value fields, and click `Add variable` for each of the below vars:
    1. `PORT` = `3000`
    1. `REGISTRY_DOMAIN` = `gcr.io`
    1. `REGISTRY_ACCOUNT` = [your GCP project ID]
    1. `NAMESPACE` = [your desired K8S namespace]
    1. `GITHUB_TOKEN` = [your GitHub personal access token]
    1. `API_KEY` = [your Codefresh API key]
    1. `PIPELINE_ID` = [the ID of the next pipeline you will create. See next section]
1. Under `WORKFLOW` toggle from `Basic` to `YAML`, and select `Use YAML from Repository `
    1. `Path to YAML` type `codefresh-actions.yaml`
1. Click `Save` to save these configurations for this pipeline

## Configure a PR release pipeline

Triggered only by the first "PR action filter" pipeline, this pipeline is responsible for building the Pull Request release, and updating the PR accordingly.

1. Click `Add Pipeline`
1. Name this second pipeline "PR release"
1. Copy the pipeline ID, and add to the `PIPELINE_ID` environment variable in the previous pipeline (you can get the ID from the [Codefresh CLI](https://github.com/codefresh-io/cli) or by temporarily enabling the webhook option which contains the ID)
1. Do not enable `Configuration` > `General Settings` > `Automated build` > `Add webhook`
1. Do not bother configuring `Configuration` > `Environment Variables`, as they will be ignored since this pipeline is only built from the previous one, which in YAML is configured to pass along it's own environment variables.
1. Under `WORKFLOW` toggle from `Basic` to `YAML`, and select `Use YAML from Repository `
    1. `Path to YAML` type `codefresh.yaml`
1. Click `Save` to save these configurations for this pipeline

## Create a test Pull Request

In GitHub UI:

1. Browse to your new test repo
1. Click [Create new file](https://help.github.com/articles/creating-new-files/)
1. Name your file `test` (file can be empty), select `Create a new branch for this commit and start a pull request`, and click `Propose new file`
1. On the next page, click `Create pull request`

## Expected results

In GitHub UI (or API):

1. During build, the Pull Request Status should contain two pending checks:
    1. `Codefresh - Build is pending or running`, linking to the Codefresh build
    1. `PR Release — Waiting for successful build`
1. On success, the Pull Request Status should contain two successful checks:
    1. `Codefresh - Build passed`, linking to the Codefresh build
    1. `PR Release — Deployed to codefresh namespace`, linking to the built PR release (printing only "Hello")
