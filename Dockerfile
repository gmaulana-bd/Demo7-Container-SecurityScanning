# D5 Container Misconfiguration Demo (FIXED VERSION)
#
# AXA Secure SDLC Training - Demo 7, Activity 4 (Slide 65)
# Every problem from the vulnerable Dockerfile is corrected:
#   - Current, minimal base image (Alpine, far smaller CVE surface than old Debian)
#   - Explicit non-root USER
#   - No unnecessary packages
#
# The Trivy scan in CI/CD PASSES on this Dockerfile.

# FIXED: current minimal Alpine base. Small attack surface, actively patched.
FROM alpine:3.23

# FIXED: create a dedicated non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the app and make it executable
COPY app.sh /app/app.sh
RUN chmod +x /app/app.sh && chown appuser:appgroup /app/app.sh

# FIXED: switch to the non-root user (Trivy DS002 satisfied)
USER appuser

ENTRYPOINT ["/app/app.sh"]
