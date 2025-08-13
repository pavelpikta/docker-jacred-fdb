# Docker Jacred-FDB

[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/pavelpikta/docker-jacred-fdb?sort=semver&logo=github)](https://github.com/pavelpikta/docker-jacred-fdb/releases/latest)
[![Release Workflow](https://img.shields.io/github/actions/workflow/status/pavelpikta/docker-jacred-fdb/release.yml?branch=main&label=Release%20Workflow&logo=github)](https://github.com/pavelpikta/docker-jacred-fdb/actions/workflows/release.yml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-docker--jacred--fdb-blue?logo=github)](https://ghcr.io/pavelpikta/jacred-fdb)

[![Semantic Release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![License](https://img.shields.io/github/license/pavelpikta/docker-jacred-fdb?color=blue)](https://github.com/pavelpikta/docker-jacred-fdb/blob/main/LICENSE)

A Docker image for [Jacred](https://github.com/immisterio/jacred-fdb) - a torrent tracker aggregator that provides a unified API for multiple torrent trackers. This containerized implementation offers enhanced security, multi-architecture support, and automated CI/CD workflows.

## 🚀 Features

- **Multi-Architecture Support**: Available for `amd64`, `arm64`, and `arm` platforms
- **Security-First**: Non-root user execution, minimal attack surface
- **Robust Operations**: Health checks, graceful shutdown, signal handling
- **Automated CI/CD**: Semantic versioning with automated releases
- **SBOM & Attestations**: Supply chain security with SLSA attestations
- **Optimized Build**: Self-contained .NET 8 binary with AOT compilation
- **Configuration Management**: Persistent configuration with volume mounts

## 📋 Quick Start

### Docker Run

```bash
docker run -d \
  --name jacred \
  -p 9117:9117 \
  -v jacred-config:/app/config \
  -v jacred-data:/app/Data \
  --restart unless-stopped \
  ghcr.io/pavelpikta/jacred-fdb:latest
```

### Docker Compose

```yaml
version: '3.8'

services:
  jacred:
    image: ghcr.io/pavelpikta/jacred-fdb:latest
    container_name: jacred
    restart: unless-stopped
    ports:
      - "9117:9117"
    volumes:
      - jacred-config:/app/config
      - jacred-data:/app/Data
    environment:
      - TZ=Europe/London
      - UMASK=0027
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--spider", "http://127.0.0.1:9117"]
      interval: 30s
      timeout: 15s
      retries: 3
      start_period: 45s

volumes:
  jacred-config:
  jacred-data:
```

## 🐳 Available Images

### Registries

| Registry | Image | Description |
|----------|-------|-------------|
| GitHub Container Registry | `ghcr.io/pavelpikta/jacred-fdb` | Latest builds with attestations |
| GitHub Container Registry | `ghcr.io/pavelpikta/jacred-fdb:1.0.0` | Specific version example |

### Tags

| Tag | Description | Update Frequency |
|-----|-------------|------------------|
| `latest` | Latest stable release from `main` branch | On new releases |
| `develop` | Development builds from `develop` branch | On each commit |
| `v1.2.3` | Specific semantic version | Immutable |
| `sha-abcd123` | Specific commit SHA | Immutable |

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `UTC` | Container timezone |
| `UMASK` | `0027` | File creation mask |
| `ASPNETCORE_URLS` | `http://0.0.0.0:9117` | Application listen address |
| `ASPNETCORE_ENVIRONMENT` | `Production` | ASP.NET Core environment |

### Volumes

| Path | Purpose | Required |
|------|---------|----------|
| `/app/config` | Configuration files | ✅ |
| `/app/Data` | Application data and logs | ✅ |

### Initial Configuration

The container automatically creates an initial configuration file (`init.conf`) on first run:

```json
{
  "listenip": "any",
  "listenport": 9117,
  "apikey": "",
  "mergeduplicates": true,
  "openstats": true,
  "opensync": true,
  "log": true,
  "syncapi": "http://redapi.cfhttp.top",
  "synctrackers": ["rutracker", "rutor", "kinozal", "nnmclub", "megapeer", "bitru", "toloka", "lostfilm", "baibako", "torrentby", "selezen"],
  "maxreadfile": 200,
  "tracks": true,
  "tracksdelay": 20000,
  "timeStatsUpdate": 60,
  "timeSync": 60
}
```

## 🏗️ Build Information

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `ALPINE_VERSION` | `3.22.1` | Base Alpine Linux version |
| `JACRED_VERSION` | `93c1b7b1...` | Jacred source commit SHA |
| `DOTNET_VERSION` | `8.0` | .NET runtime version |

### Multi-Stage Build

The Docker image uses a multi-stage build process:

1. **Builder Stage**: Compiles Jacred from source using .NET 8 SDK
2. **Runtime Stage**: Minimal Alpine Linux with only required dependencies

### Optimization Features

- Self-contained deployment (no .NET runtime required)
- Single-file executable with compression
- Ahead-of-time (AOT) compilation optimizations
- Trimmed runtime dependencies

## 🔒 Security

### Container Security

- **Non-root execution**: Runs as user `jacred` (UID: 1000)
- **Minimal attack surface**: Alpine Linux base with essential packages only
- **Read-only filesystem**: Application binaries are read-only
- **Signal handling**: Graceful shutdown on SIGTERM/SIGINT

### Supply Chain Security

- **SBOM Generation**: Software Bill of Materials for dependency tracking
- **SLSA Attestations**: Build provenance and integrity verification
- **Dependency Updates**: Automated via Dependabot
- **Security Scanning**: Integrated vulnerability assessment

### Verification

Verify image signatures and attestations:

```bash
# Install cosign
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verify attestation
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp 'https://github\.com/pavelpikta/docker-jacred-fdb/\.github/workflows/.+' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/pavelpikta/jacred-fdb:latest
```

## 🚦 Health Checks

The container includes a built-in health check that verifies the application is responding:

```dockerfile
HEALTHCHECK --interval=30s \
    --timeout=15s \
    --start-period=45s \
    --retries=3 \
    --start-interval=5s \
    CMD wget --quiet --spider http://127.0.0.1:9117 || exit 1
```

## 📊 Monitoring

### Application Logs

```bash
# View real-time logs
docker logs -f jacred

# View logs with timestamps
docker logs -t jacred
```

### Health Status

```bash
# Check container health
docker inspect jacred --format='{{.State.Health.Status}}'

# View health check logs
docker inspect jacred --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
```

## 🔧 Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check container logs
docker logs jacred

# Verify volume mounts
docker inspect jacred --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{.Mode}}{{end}}'
```

#### Permission Issues

```bash
# Fix volume permissions
sudo chown -R 1000:1000 /path/to/your/volumes
```

#### Configuration Problems

```bash
# Recreate default configuration
docker exec jacred rm -f /app/config/init.conf
docker restart jacred
```

### Debug Mode

Run container with debug output:

```bash
docker run --rm -it \
  -p 9117:9117 \
  -v jacred-config:/app/config \
  ghcr.io/pavelpikta/jacred-fdb:latest \
  /bin/sh
```

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes using [Conventional Commits](https://conventionalcommits.org/):

   ```bash
   git commit -m "feat: add amazing new feature"
   ```

4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Commit Convention

We use [Conventional Commits](https://conventionalcommits.org/) for automated versioning:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `docs:` - Documentation changes
- `ci:` - CI/CD changes
- `chore:` - Maintenance tasks
- `BREAKING CHANGE:` - Breaking changes (major version bump)

### Local Development

```bash
# Clone the repository
git clone https://github.com/pavelpikta/docker-jacred-fdb.git
cd docker-jacred-fdb

# Build locally
docker build -t jacred-fdb:local .

# Test the build
docker run --rm -p 9117:9117 jacred-fdb:local
```

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).

## 🙏 Acknowledgments

- [Jacred-FDB](https://github.com/immisterio/jacred-fdb) - The amazing torrent tracker aggregator
- [Alpine Linux](https://alpinelinux.org/) - Secure, lightweight base image
- [GitHub Actions](https://github.com/features/actions) - CI/CD automation
- [Semantic Release](https://semantic-release.gitbook.io/) - Automated versioning

---

**If this project helped you, please consider giving it a ⭐!**

[![Report Bug](https://img.shields.io/badge/Report-Bug-red?logo=github)](https://github.com/pavelpikta/docker-jacred-fdb/issues)  [![Request Feature](https://img.shields.io/badge/Request-Feature-blue?logo=github)](https://github.com/pavelpikta/docker-jacred-fdb/issues)
