# Contributing to debian-anon-vm

Thank you for your interest in improving `debian-anon-vm`! We welcome contributions from developers, security researchers, and privacy advocates.

## Code of Conduct

Please treat everyone with respect and empathy. We are committed to providing a friendly, safe, and welcoming environment for all contributors.

---

## How to Contribute

### 1. Reporting Bugs & Feature Requests

* Search existing [Issues](https://github.com/aleaz/debian-anon-vm/issues) to avoid duplicates.
* Use the provided issue templates for [Bug Reports](.github/ISSUE_TEMPLATE/bug_report.md) or [Feature Requests](.github/ISSUE_TEMPLATE/feature_request.md).
* For security-sensitive issues or traffic leaks, please follow [SECURITY.md](SECURITY.md).

### 2. Submitting Pull Requests (PRs)

1. Fork the repository and create a feature branch:

   ```bash
   git checkout -b feature/my-cool-improvement
   ```

2. Make your changes adhering to the coding standards below.
3. Test your changes using `--dry-run` and the built-in test suite:

   ```bash
   bash -n anon-vm
   sudo ./anon-vm check
   ```

4. Commit your changes with clear, descriptive commit messages:

   ```bash
   git commit -m "feat(hardening): add RFC 1337 TIME-WAIT assassination protection"
   ```

5. Push to your branch and submit a Pull Request against `main`.

---

## Coding Standards

### Bash Scripts (`anon-vm`)

* **Strict Mode:** Always use `set -euo pipefail`.
* **Portability:** Scripts must run on standard Debian GNU/Linux 12 (Bookworm) and 13 (Trixie) across both `ARM64` (Apple Silicon) and `x86_64` architectures.
* **Idempotency:** Every command or function must be safe to run multiple times without duplicating entries or causing errors.
* **Dry-Run Support:** Every state-modifying action must respect the `DRY_RUN` flag.
* **Linting:** Code must pass `shellcheck` with zero errors or warnings:

  ```bash
  shellcheck anon-vm
  ```

### Documentation

* All documentation must be written in standard, clean Markdown.
* Lint Markdown files using `markdownlint`:

  ```bash
  npx markdownlint-cli *.md docs/*.md
  ```
