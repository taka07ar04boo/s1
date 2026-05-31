# Contributing to S1 Sovereign

First off, thank you for considering contributing to S1! 
The S1 Sovereign project operates as a DB-first governance layer.

## The S1 Sovereign Codex
**Important**: All contributions must strictly adhere to the S1 Sovereign Codex.
1. **S1 Only**: Avoid intertwining logic related to H1, A3, or S2 architectures. This is an S1 standalone system.
2. **Zero-Trust Governance**: Do not bypass event triggers or create loopholes (e.g., changing `session_replication_role` in PostgreSQL).
3. **DB-First**: State and tasks should be managed via PostgreSQL.

## Setting Up the Development Environment
1. Clone the repository: `git clone https://github.com/taka07ar04boo/s1.git`
2. Install dependencies using your preferred Python package manager (e.g., `uv` or `pip`).
3. Set up the local PostgreSQL database as defined in the `sql/` directory.

## Submitting Pull Requests
1. Fork the repository and create your branch from `main`.
2. Ensure your code conforms to the S1 architectural guidelines.
3. Include tests if appropriate.
4. Open a Pull Request and reference any related issues.
