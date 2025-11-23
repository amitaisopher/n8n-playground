# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Custom Dockerfile extending official n8n image with Python and Node.js modules
- Pre-installed Python packages: requests, pandas, numpy, beautifulsoup4, lxml, openpyxl, python-dateutil, pytz
- Pre-installed Node.js packages: axios, lodash, moment, uuid, csv-parse, csv-stringify
- Documentation for using custom modules in n8n Code nodes
- Instructions for adding additional Python and Node.js packages
- CHANGELOG.md to track project changes

### Changed
- Docker Compose files now build from Dockerfile instead of using official image directly
- Updated README with custom modules section and usage examples
- Simplified docker-compose structure: removed base file, each environment is self-contained
- Updated Quick Start section to include build step
- Enhanced troubleshooting section with module-related issues

### Removed
- Removed unused base docker-compose.yml file (consolidated into environment-specific files)

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
