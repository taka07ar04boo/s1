# S1 Sovereign Installation & Setup Guide (導入手順書)

This guide provides step-by-step instructions to install and configure the S1 Sovereign package.

## 1. Prerequisites (前提条件)

- Python 3.8 or higher
- PostgreSQL (or access to the `pckeiba` database)
- Git

## 2. Clone the Repository (リポジトリのクローン)

First, clone the S1 repository to your local machine:

```bash
git clone https://github.com/taka07ar04boo/s1.git
cd s1
```

## 3. Install the Package (パッケージのインストール)

We recommend using a virtual environment. Install the package in editable mode using `pip`:

```bash
# Optional: Create and activate a virtual environment
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install the package
pip install -e .
```

This will install `s1-sovereign` and its dependencies (`psycopg2-binary`, `python-dotenv`).

## 4. Configuration (設定)

The S1 package uses environment variables for database configuration.

1. Copy the example configuration file:
```bash
# On Windows:
copy .env.example .env
# On Linux/Mac:
cp .env.example .env
```

2. Edit the `.env` file and update the database credentials to match your PostgreSQL setup:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pckeiba
DB_USER=postgres
DB_PASSWORD=your_password_here
```

## 5. Verify Installation & Initialization (インストールの確認と初期化)

You can verify the installation by calling the CLI tool:

```bash
s1-sovereign --help
```

### Initialize Database Schema (データベーススキーマの初期化)

Before using the waterfall orchestrator, initialize the necessary database tables:

```bash
s1-sovereign waterfall start "Initial Setup" "Setting up S1 DB tables"
```
*(This command automatically initializes the schema if it does not exist).*

## 6. Running the Tools (ツールの実行)

The package provides several command-line utilities. Here are some examples:

- **Auto Task Processor**: `s1-sovereign auto-task`
- **Data Mining Orchestrator**: `s1-sovereign data-mining`
- **Delegate Tasks**: `s1-sovereign delegate`
- **Queue Monitor**: `s1-sovereign queue`
- **Waterfall Orchestrator**: `s1-sovereign waterfall [start|approve|delegate|status] ...`

## Troubleshooting (トラブルシューティング)

- **Database Connection Error**: Ensure PostgreSQL is running, and the credentials in your `.env` file are correct.
- **Command Not Found**: Ensure your Python virtual environment is activated, or that your Python `Scripts`/`bin` folder is in your system's PATH.
