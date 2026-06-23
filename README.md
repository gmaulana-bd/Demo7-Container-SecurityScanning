# D5 Container Misconfiguration (Docker + Trivy): CI/CD Demo

**Demo 7, Activities 3 and 4 in the AXA Secure SDLC Training (slide 65).**

This demo shows container image security scanning in CI/CD. Trivy scans a Docker image for CVEs and the Dockerfile for misconfigurations. The pipeline FAILS when the image uses an old base with CVEs and runs as root, and PASSES after the Dockerfile is hardened.

## What this demo proves

When a developer opens a PR with an insecure Dockerfile, the CI/CD pipeline:

1. Builds the Docker image
2. Runs Trivy to scan for OS CVEs and misconfigurations
3. Fails the build on Critical/High CVEs or root-user violations
4. Blocks the PR merge button until the Dockerfile is hardened

Same gate concept as D3b and D4, applied to container images.

## What's in this folder

```
.
├── README.md                          (you are here)
├── app.sh                             (trivial app the container runs)
├── Dockerfile                         (the image being scanned)
├── VULNERABLE_Dockerfile.txt          (the insecure version, for the feature branch)
└── .github/workflows/
    └── container-security.yml         (Trivy scan + Security Gate)
```

The `Dockerfile` content differs by branch:
- On `main`: the HARDENED version (scan passes)
- On `vulnerable-feature`: the INSECURE version (scan fails)

## The problems (vulnerable version)

| Issue | Detected by | Slide 65 mapping |
|---|---|---|
| Old base image (debian:11.0) with OS CVEs | Trivy image scan | "find base-image CVEs" |
| Runs as root (no USER directive) | Trivy config scan (DS002) | "find non-root violation" |

The fixed version uses a current minimal base (alpine:3.23), creates a non-root user, and switches to it, matching "use distroless base, add USER directive" from the slide.

## Important note on Trivy and supply chain safety

The `aquasecurity/trivy-action` GitHub Action was compromised twice in 2026 (March 1 and March 19), with credential-stealing malware pushed to most of its version tags. For that reason, this workflow does NOT use the action. Instead it installs the Trivy binary directly from Aqua's official APT repository, pinned to a known-safe version (v0.69.3, per the official advisory).

This is itself a teaching point: when even your security scanner's distribution channel can be compromised, pinning to verified versions and avoiding mutable tags matters. This ties directly to the Demo 6 (pipeline pollution) lesson.

## Trainer setup (one-time, before the session)

### Step 1: Push the hardened version as main

```bash
git init
git add .
git commit -m "Initial hardened Dockerfile with Trivy pipeline"
git branch -M main
git remote add origin https://github.com/YOUR-ORG/YOUR-D5-REPO.git
git push -u origin main
```

Confirm main's pipeline runs green (Container Scan passes, Security Gate passes).

### Step 2: Create the vulnerable-feature branch

```bash
git checkout -b vulnerable-feature
```

Replace the contents of `Dockerfile` with the vulnerable version (from `VULNERABLE_Dockerfile.txt`: debian:11.0 base, no USER directive). Then:

```bash
git add Dockerfile
git commit -m "Add container image for new service"
git push -u origin vulnerable-feature
```

### Step 3: Make the repo public (free-plan branch protection requirement)

Settings -> General -> Change visibility -> Make public. This demo has no secrets, so public is safe.

### Step 4: Set up branch protection on main

Settings -> Branches -> Add rule:
- Branch name pattern: `main`
- Require a pull request before merging
- Require status checks to pass before merging -> select `Security Gate`
- Do not allow bypassing the above settings
- Save

### Step 5: Verify both states

- main pipeline: green (hardened Dockerfile passes)
- vulnerable-feature pipeline: red (Trivy finds CVEs + root violation)

### Step 6: Open the PR

Open a PR from `vulnerable-feature` into `main`. Trivy fails, Security Gate fails, Merge button greys out.

## During the session (the demo flow)

Approximate timing: 4 minutes.

### Part 1: The insecure PR (1 min)
"A developer opened a PR adding a container image for a new service. Let's see what the container scan finds."

### Part 2: The failed scan (1.5 min)
Click into the Container Scan job. Show two failures:
- "Trivy scanned the image and found Critical and High CVEs in the old Debian 11 base."
- "Trivy also scanned the Dockerfile and found it runs as root, no USER directive. If this container is compromised, the attacker has root inside it."

### Part 3: The blocked merge (1 min)
"Merging is blocked. The Merge button is greyed out. This insecure image cannot reach production."

### Part 4: The fix (0.5 min, optional)
Push the hardened Dockerfile (alpine:3.23, non-root user). Pipeline re-runs, goes green.
"The developer switches to a current minimal base, creates a non-root user, switches to it. Same scan, now it passes."

## A note on verification

The IaC half of Demo 7 (D4, Checkov) was verified by running Checkov directly. This container half was built from documented Trivy behavior but could not be executed in the build environment used to create it (no Docker/Trivy network access there). Before your session, run the vulnerable branch once and confirm:
- Trivy image scan reports CRITICAL/HIGH CVEs on debian:11.0 (it will; that base is old)
- Trivy config scan reports the root-user finding (DS002)
- The hardened branch passes both

If the hardened alpine:3.23 base shows any HIGH CVE at scan time (Alpine is usually clean but CVEs emerge), you can either bump to the latest Alpine patch or add a scoped `.trivyignore` for that specific CVE, the same triage pattern used in the other demos.

## Reference

- AXA CLDEV-CFG-01 (container image hardening)
- Trivy by Aqua Security (the scanner)
- Trivy supply chain advisory: GHSA-69fq-xp46-6x23
- Tools named on slide 65: Checkov, tfsec, Trivy, Aqua, Qualys Container Security
