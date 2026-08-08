# ObjoBuilder

This repository contains GitHub Actions workflows for building, publishing and signing applications created with **Objo Studio**.

Most workflows in this repository are thin wrappers around reusable workflows hosted in the **ObjoPublisher** repository.

- **Reusable workflows:** https://github.com/madamov/ObjoPublisher
- **This repository:** https://github.com/madamov/ObjoBuilder

The workflows prefixed with **ObjoPublisher** simply provide project-specific parameters and secrets, while the reusable workflows perform all publishing, signing and artifact generation.

---

# Available workflows

| Workflow | Description |
|----------|-------------|
| **ObjoPublisher for macOS** | Publishes macOS applications (Apple Silicon and/or Intel), optionally signs and notarizes them, and uploads DMG artifacts. |
| **ObjoPublisher for Linux** | Publishes Linux applications for one or more targets and uploads generated archives. |
| **ObjoPublisher for Windows** | Publishes Windows applications and signs generated MSIX packages using the official Azure Trusted Signing GitHub Action. |
| **ObjoPublisher for Windows (Objo signing)** | Publishes Windows applications and lets Objo Studio perform Azure Trusted Signing during publishing. |

## Example workflow

This repository also contains a sample workflow named **`check_syntax.yml`**. It demonstrates how to restore a cached Objo Studio installation, activate an Objo Studio license, and run the `objo check` command to verify the syntax of an Objo solution.

The workflow is intended as a reference implementation for projects that need to perform automated syntax validation without publishing an application. You can use it as a starting point for creating your own build, test, or validation workflows.

---

## Caching the latest Objo Studio

The **`cache_objo_studio.yml`** workflow is a utility workflow that downloads and caches the latest released version of Objo Studio for all supported GitHub Actions runner platforms:

- macOS
- Linux
- Windows

Running this workflow proactively refreshes the GitHub Actions caches, allowing subsequent build and publish workflows to restore Objo Studio from cache instead of downloading it during each run. This reduces workflow execution time and minimizes external downloads.

---

# Repository secrets

The reusable workflows require several GitHub repository secrets.

Some are platform-specific while others are shared.

## Objo Studio

| Secret | Required by | Description |
|---------|-------------|-------------|
| `OBJO_LICENSE` | macOS, Linux, Windows | Objo Studio license key used to activate Objo Studio before publishing. The reusable workflows automatically deactivate the license when publishing finishes, even if the workflow fails. |

---

## Apple code signing

Required only for macOS publishing.

| Secret | Description |
|---------|-------------|
| `APPLE_CERTIFICATE` | Base64-encoded Apple signing certificate (.p12). |
| `APPLE_CERTIFICATE_NAME` | Name of the signing identity contained in the certificate. |
| `APPLE_CERTIFICATE_PASSWORD` | Password protecting the .p12 certificate. |
| `APPLE_TEAM_ID` | Apple Developer Team ID. |
| `APPLE_ID` | Apple Developer Apple ID email address. |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple App-Specific Password used by `notarytool` during notarization. |

If any Apple signing secret is missing, the reusable macOS workflow automatically publishes an **unsigned** application.

---

## Azure Trusted Signing

Required only for Windows publishing.

| Secret | Description |
|---------|-------------|
| `AZURE_TENANT_ID` | Microsoft Entra (Azure AD) tenant ID. |
| `AZURE_CLIENT_ID` | Application (client) ID of the Azure service principal. |
| `AZURE_CLIENT_SECRET` | Client secret for the Azure service principal. |
| `AZURE_ENDPOINT` | Azure Trusted Signing endpoint (for example `https://wus2.codesigning.azure.net/`). |
| `AZURE_ACCOUNTNAME` | Azure Trusted Signing account name. |
| `AZURE_CERTIFICATEPROFILENAME` | Azure Trusted Signing certificate profile name. |
| `AZURE_PACKAGEPUBLISHER` | Publisher value written into the generated MSIX package manifest. This must match the publisher configured in the Trusted Signing certificate profile. |
| `AZURE_TIMESTAMPURL` *(optional)* | RFC3161 timestamp server URL. If omitted, Windows packages are signed without timestamping. |

---

# Typical workflow

```text
Checkout source
        │
        ▼
Determine Objo Studio version
        │
        ▼
Restore Objo Studio from cache
        │
        ▼
Download Objo Studio if cache miss
        │
        ▼
Activate Objo license
        │
        ▼
Publish application
        │
        ▼
Platform-specific signing
        │
        ▼
Collect artifacts
        │
        ▼
Upload artifacts
        │
        ▼
Deactivate Objo license
```

---

# Objo Studio caching

The reusable workflows automatically cache the downloaded Objo Studio installation.

The cache key is based on the Objo Studio version.

When a newer version is requested, it is downloaded automatically and stored in the cache for future workflow runs.

---

# Output directories

The reusable workflows publish into a directory under the current runner user's home directory.

Examples:

| Platform | Default output directory |
|----------|--------------------------|
| macOS | `$HOME/Documents/Publish` |
| Linux | `$HOME/Publish` |
| Windows | `%USERPROFILE%\Publish` |

The output directory can be overridden using the `output-directory` workflow input.

---

# Artifacts

Generated artifacts are uploaded automatically.

| Platform | Artifact |
|----------|----------|
| macOS | `.dmg` |
| Linux | `.tar.gz`, `.tgz` or `.zip` |
| Windows | `.msix` |

---

# Multiple publish targets

The reusable workflows support publishing multiple targets in a single run.

Examples:

```yaml
targets: "osx-arm64, osx-x64"
```

```yaml
targets: "linux-x64, linux-arm64"
```

```yaml
targets: "win-x64, win-arm64"
```

Whitespace around target names is ignored.

---

# Using a different Objo Studio version

By default the reusable workflows automatically detect the latest released Objo Studio version.

To publish using a specific version:

```yaml
with:
  objo-version: "26.7.1"
```

---

# Reusable workflows

The reusable workflows are maintained in:

https://github.com/madamov/ObjoPublisher

This repository contains only project-specific wrapper workflows.

Keeping publishing logic in a separate repository allows improvements and fixes to be shared by all Objo projects using these workflows.
