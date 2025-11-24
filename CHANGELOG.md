# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **External mode configuration** now uses official `n8nio/runners` image instead of custom Dockerfile
- **Broker URI protocol** corrected from `ws://` to `http://` for proper task runner communication
- **Task runner environment variables** properly scoped to runners container only
- **Code node hanging issue** in external mode resolved with proper configuration
- Container startup sequence and health checks for external mode

### Added
- **Dual-mode task runner architecture** supporting both internal and external modes
- **Four complete Docker Compose configurations**:
  - `docker-compose.internal.dev.yml` - Internal mode development
  - `docker-compose.internal.prod.yml` - Internal mode production
  - `docker-compose.external.dev.yml` - External mode development
  - `docker-compose.external.prod.yml` - External mode production
- **Dedicated Dockerfiles for each mode**:
  - `Dockerfile.runners.internal` - Extends n8n with embedded runners
  - `Dockerfile.runners.external` - Separate task runner container
- **Environment files for all configurations**:
  - `.env.development` - Internal mode development
  - `.env.production` - Internal mode production
  - `.env.external.development` - External mode development
  - `.env.external.production` - External mode production
- Task runner configuration file (`n8n-task-runners.json`) with allowlisted packages
- **docs/SETUP.md** - Comprehensive setup guide with mode comparison and decision matrix
- Python packages in runners: httpx, beautifulsoup4, lxml, openpyxl, python-dateutil, pytz
- Node.js packages in runners: axios, lodash, moment, uuid, csv-parse, csv-stringify
- Task runner environment variables for authentication and broker communication
- Mode comparison table in README showing trade-offs
- Architecture diagrams for both internal and external modes
- Instructions for switching between modes
- Native Python runner support (beta) via `N8N_NATIVE_PYTHON_RUNNER=true`
- Resource limits configuration in production compose files
- Container naming patterns to prevent conflicts between modes

### Changed
- Switched from custom n8n image to official `n8nio/n8n:latest` image
- Code execution now happens via task runners (internal child processes or external containers)
- Reorganized file structure with clear mode and environment naming
- Updated README with mode selection guidance and comparison
- Enhanced documentation with mode-specific instructions
- Updated quick start guide to cover all four configurations
- Improved troubleshooting section with mode-specific diagnostics

### Removed
- Old generic docker-compose.dev.yml and docker-compose.prod.yml (replaced with mode-specific versions)
- Generic Dockerfile.runners (split into internal and external variants)
- Old security environment variables that are now handled by task runners

### Fixed
- Python asyncio operations properly documented as unsupported (use synchronous alternatives)
- Security restrictions properly enforced via RestrictedPython in task runners
- Container naming conflicts when running multiple modes
- Environment file loading clarity for each configuration

### Technical Details

#### Internal Mode
- Task runners run as child processes within n8n container
- Simple single-container architecture (n8n + postgres)
- Packages installed directly in n8n image via `Dockerfile.runners.internal`
- Package allowlist via `NODE_FUNCTION_ALLOW_EXTERNAL` environment variable
- Best for: Development, small-medium production, resource efficiency

#### External Mode
- Task runners run in separate sidecar container
- Three-container architecture (n8n + task-runners + postgres)
- Packages installed in dedicated runners image via `Dockerfile.runners.external`
- Package allowlist via `n8n-task-runners.json` configuration file
- Authentication via `N8N_RUNNERS_AUTH_TOKEN`
- WebSocket communication on port 5679
- Best for: High-security production, independent scaling
- Note: Requires official `n8nio/runners` image (placeholder currently used)

### Migration Guide

If you were using the previous setup:

1. **Choose your mode** (internal recommended for most users)
2. **Backup your data**: `tar czf backup.tar.gz data/`
3. **Stop old containers**: `docker compose down`
4. **Use new compose file**:
   ```bash
   # For internal mode dev:
   docker compose -f docker-compose.internal.dev.yml build
   docker compose -f docker-compose.internal.dev.yml up -d
   ```
5. Your data in `./data/` will be preserved and work with any mode

## [1.0.0] - 2025-11-20

### Added
- Initial project setup with Docker Compose
- Self-contained docker-compose files for development and production environments
- PostgreSQL 16 database integration
- Environment-specific configuration files (.env.development, .env.production)
- Local directory volumes for data persistence (./data/n8n and ./data/postgres)
- Separate Docker networks for service isolation
- Health checks for PostgreSQL service
- Container dependency management (n8n waits for healthy PostgreSQL)
- Development environment with exposed PostgreSQL port (5432) for debugging
- Production environment with resource limits (CPU and memory)
- Comprehensive README.md with:
  - Quick start guide
  - Environment configuration documentation
  - Data persistence and backup strategies
  - Security considerations
  - Troubleshooting guide
- .gitignore file to exclude sensitive data and local files
- Example environment file (.env.example) with all available variables

### Technical Details
- n8n runs on port 5678
- PostgreSQL uses port 5432 (exposed in dev, internal only in prod)
- Data persisted in ./data directory for easy backups
- All environment variables loaded via env_file directive
- PostgreSQL credentials mapped from n8n format to PostgreSQL format in docker-compose

### Security
- Environment files excluded from version control
- Encryption key required for n8n
- Strong password requirements documented
- File permissions enforcement enabled
- Task runners enabled for improved security
