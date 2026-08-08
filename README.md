# ObjoBuilder

This repository contains GitHub Actions workflows for building, publishing, signing and distributing applications created with **Objo Studio**.

Most workflows in this repository are thin wrappers around reusable workflows hosted in the **ObjoPublisher** repository.

- **Reusable workflows:** https://github.com/madamov/ObjoPublisher
- **This repository:** https://github.com/madamov/ObjoBuilder

The workflows prefixed with **ObjoPublisher** simply provide project-specific parameters and secrets, while the reusable workflows perform all publishing, signing and artifact generation.

The repository now contains two sets of publishing examples:

1. The original workflows demonstrate how to download published GitHub Actions artifacts and upload them to an external SFTP server from the calling workflow.
2. The newer SFTP workflows demonstrate the built-in SFTP upload support provided directly by the ObjoPublisher reusable workflows.

Both approaches are intentionally kept in this repository as examples.

---

# Available workflows

| Workflow | Description |
|----------|-------------|
| **ObjoPublisher for macOS** | Publishes macOS applications (Apple Silicon and/or Intel), optionally signs and notarizes them, and uploads DMG artifacts. |
| **ObjoPublisher for Linux** | Publishes Linux applications for one or more targets and uploads generated archives. |
| **ObjoPublisher for Windows** | Publishes Windows applications and signs generated MSIX packages using the official Azure Trusted Signing GitHub Action. |
| **ObjoPublisher for Windows (Objo signing)** | Publishes Windows applications and lets Objo Studio perform Azure Trusted Signing during publishing. |

Three additional example workflows demonstrate the new built-in SFTP support in ObjoPublisher:

| Workflow | Description |
|----------|-------------|
| `objopublisher_publish_macos_sftp.yml` | Publishes macOS DMG files and lets the reusable ObjoPublisher workflow upload them directly to SFTP. |
| `objopublisher_publish_linux_sftp.yml` | Publishes Linux archives and lets the reusable ObjoPublisher workflow upload them directly to SFTP. |
| `objopublisher_publish_windows_sftp.yml` | Publishes and signs Windows MSIX packages and lets the reusable ObjoPublisher workflow upload them directly to SFTP. |

The original workflows remain available to demonstrate the alternative approach where the calling workflow downloads the GitHub Actions artifacts and performs the SFTP upload itself.

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

# SFTP upload examples

ObjoBuilder demonstrates two ways of uploading published applications to an SFTP server.

## Built-in ObjoPublisher SFTP upload

The newer `_sftp` example workflows pass SFTP configuration directly to the reusable ObjoPublisher workflows.

The relevant reusable workflow inputs are:

```yaml
with:
  sftp-url: ${{ vars.SFTP_SERVER_URL }}
  fail-on-sftp-error: true
```

SFTP credentials are passed as reusable workflow secrets:

```yaml
secrets:
  sftp-username: ${{ secrets.BINARIES_USER }}
  sftp-password: ${{ secrets.BINARIES_PASSWORD }}
```

SFTP upload is performed only when all three values are available:

- `sftp-url`
- `sftp-username`
- `sftp-password`

If any one of these values is missing or empty, the SFTP upload is skipped and publishing continues normally.

Artifacts are uploaded into platform-specific directories:

| Platform | SFTP destination |
|----------|------------------|
| macOS | `<sftp-url>/macos/` |
| Linux | `<sftp-url>/linux/` |
| Windows | `<sftp-url>/windows/` |

The normal GitHub Actions artifact upload still happens before the SFTP upload, so successfully generated packages remain available from the workflow run even if the external upload fails.

## SFTP failure handling

The optional input

```yaml
fail-on-sftp-error: true
```

controls what happens if publishing succeeds but the SFTP upload fails.

| Build | SFTP upload | `fail-on-sftp-error` | Result |
|-------|-------------|----------------------|--------|
| Success | Success | either | Exit code `0` |
| Failure | Not attempted | either | Exit code `1` |
| Success | Failure | `true` | Exit code `2` |
| Success | Failure | `false` | Exit code `0` |
| Success | Skipped | either | Exit code `0` |

This makes it possible to distinguish an application build failure from a distribution/upload failure.

The reusable workflows also expose an `sftp-upload` workflow output with one of these values:

```text
success
failed
skipped
```

## Original artifact-download approach

The original workflows remain in this repository as examples of a different deployment pattern.

In those workflows:

1. ObjoPublisher builds the application.
2. ObjoPublisher stores the generated files as GitHub Actions artifacts.
3. The calling ObjoBuilder workflow downloads those artifacts.
4. The calling workflow performs the SFTP upload itself.

This approach is useful when you need to perform additional processing between publishing and deployment, for example:

- inspecting generated artifacts,
- modifying archives,
- virus scanning,
- generating checksums,
- uploading to several destinations,
- creating additional distribution packages,
- implementing custom deployment rules.

The newer built-in SFTP support is simpler when the only required post-build action is uploading the generated files to an SFTP server.

---

# Repository secrets

The reusable workflows require several GitHub repository secrets.

Some are platform-specific while others are shared.

## Objo Studio

| Secret | Required by | Description |
|---------|-------------|-------------|
| `OBJO_LICENSE` | macOS, Linux, Windows | Objo Studio license key used to activate Objo Studio before publishing. The reusable workflows automatically deactivate the license when publishing finishes, even if the workflow fails. |

---

## SFTP upload

Required only when SFTP upload is enabled.

| Secret | Description |
|---------|-------------|
| `BINARIES_USER` | Username used to authenticate with the SFTP server. |
| `BINARIES_PASSWORD` | Password used to authenticate with the SFTP server. |

The SFTP server URL is normally stored as a GitHub repository variable rather than a secret:

```text
SFTP_SERVER_URL
```

A typical caller passes these values to ObjoPublisher as:

```yaml
with:
  sftp-url: ${{ vars.SFTP_SERVER_URL }}
  fail-on-sftp-error: true

secrets:
  sftp-username: ${{ secrets.BINARIES_USER }}
  sftp-password: ${{ secrets.BINARIES_PASSWORD }}
```

If the URL, username or password is missing or empty, the reusable workflow skips SFTP upload.

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
Upload GitHub artifacts
        │
        ▼
(Optional)
Upload artifacts to SFTP
        │
        ▼
Deactivate Objo license
        │
        ▼
Write workflow summary
```

---

# Workflow summaries

The current ObjoPublisher reusable workflows generate a GitHub Actions workflow summary.

The summary includes information such as:

- application name,
- publish targets,
- GitHub artifact name,
- build result,
- SFTP upload result.

The SFTP status is reported as:

```text
success
failed
skipped
```

This makes it easy to distinguish a publishing problem from an external upload problem directly from the GitHub Actions run page.

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

When built-in SFTP upload is configured, the same collected artifacts are additionally uploaded to the platform-specific SFTP directory.

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

# Example using built-in SFTP upload

A typical Linux caller can be very small:

```yaml
jobs:
  publish-linux:
    uses: madamov/ObjoPublisher/.github/workflows/publish_objo_linux.yml@v1

    with:
      solution-file: MyGreatApp.objosln
      project-file: Projects/MyGreatApp/project.json
      application-name: MyGreatApp
      output-directory: Publish
      targets: "linux-x64"
      artifact-name: mygreatapp-linux-publish
      sftp-url: ${{ vars.SFTP_SERVER_URL }}
      fail-on-sftp-error: true

    secrets:
      objo-license: ${{ secrets.OBJO_LICENSE }}
      sftp-username: ${{ secrets.BINARIES_USER }}
      sftp-password: ${{ secrets.BINARIES_PASSWORD }}
```

Equivalent examples are included in this repository for macOS and Windows.

---

# Reusable workflows

The reusable workflows are maintained in:

https://github.com/madamov/ObjoPublisher

This repository contains project-specific wrapper workflows and examples showing different ways to call those reusable workflows.

Keeping publishing logic in a separate repository allows improvements and fixes to be shared by all Objo projects using these workflows.

The older examples demonstrate handling downloaded GitHub artifacts in the calling workflow, while the newer examples demonstrate the integrated SFTP deployment capabilities now available directly in ObjoPublisher.
