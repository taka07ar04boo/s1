# S1 Sovereign Architecture

This repository contains the standalone S1 Sovereign Architecture, including its governance engine, automated task processing, and meta-learning models, refactored into a fully distributable Python package.

## Package Structure
- `s1_sovereign/`: Main Python package containing S1 automation, monitoring, and orchestrator scripts.
- `sql/`: PostgreSQL logic for S1 governance rules, loophole auditing, and task execution.
- `docs/`: The S1 Sovereign Codex and related documentation.

## Installation & Setup

For a complete guide on how to install, configure, and initialize the package, please refer to the [Installation Guide (導入手順書)](docs/INSTALL.md).

### Quick Start
```bash
git clone https://github.com/taka07ar04boo/s1.git
cd s1
pip install -e .
cp .env.example .env
# Edit .env with your PostgreSQL credentials
s1-sovereign --help
```

## Features
- **Auto Task Processor**: `s1-sovereign auto-task`
- **Data Mining Orchestrator**: `s1-sovereign data-mining`
- **Delegate Tasks**: `s1-sovereign delegate`
- **Queue Monitor**: `s1-sovereign queue`
- **Waterfall Orchestrator**: `s1-sovereign waterfall`

**Note**: All sensitive credentials have been replaced with environment variables loaded via `python-dotenv`.
