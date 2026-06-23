# D5 Container Misconfiguration Demo (VULNERABLE - for vulnerable-feature branch)
#
# AXA Secure SDLC Training - Demo 7, Activity 3 (Slide 65)
# Deliberate problems that Trivy catches:
#   - Old base image with known CVEs
#   - Runs as root (no USER directive)
#   - No read-only filesystem hardening
#
# The Trivy scan in CI/CD will FAIL on this Dockerfile.

# VULNERABLE: old Debian base with many known CVEs.
# A pinned old tag guarantees Trivy finds OS-level vulnerabilities.
FROM debian:11.0

# VULNERABLE: installs packages but never creates or switches to a non-root user.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# A trivial app file
COPY app.sh /app/app.sh
RUN chmod +x /app/app.sh

# VULNERABLE: no USER directive. Container runs as root by default.
# Trivy misconfiguration scan flags this (DS002: root user).

ENTRYPOINT ["/app/app.sh"]
