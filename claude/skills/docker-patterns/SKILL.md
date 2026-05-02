---
name: docker-patterns
description: Docker patterns covering Dockerfile best practices, multi-stage builds, Compose service configuration, networking, volumes, and security. Use whenever the project contains a Dockerfile, docker-compose.yml, .dockerignore, or compose.yaml, OR the user asks about Docker, containers, docker-compose, multi-stage builds, base images, volumes, healthcheck, depends_on, even if Docker is not mentioned by name.
---

# Docker patterns

Docker Engine 29.4.2. Compose Specification (current format, supersedes 2.x and 3.x). Verify at https://docs.docker.com/engine/release-notes/ and https://docs.docker.com/compose/compose-file/.

## When to load this skill

- Project contains `Dockerfile`, `docker-compose.yml`, `compose.yaml`, or `.dockerignore`
- `FROM` instructions in any file
- `services:` key in YAML files
- User asks about Docker, containers, docker-compose, multi-stage, base images, healthcheck, volumes

## When not to load this skill

- Kubernetes without Docker build context
- Podman (different CLI, mostly compatible but diverges on rootless and socket behavior)
- Container runtimes (containerd, CRI-O) used directly without Docker tooling

## Reference files

| File                                           | Topics                                                                                       |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [dockerfile.md](reference/dockerfile.md)       | Base image selection, layer caching, RUN/COPY/ADD/CMD/ENTRYPOINT/USER/WORKDIR, .dockerignore |
| [multi-stage.md](reference/multi-stage.md)     | Multi-stage builds, named stages, COPY --from, --target, BuildKit                            |
| [compose.md](reference/compose.md)             | Services, build, ports, depends_on with healthcheck, restart, env_file, profiles, secrets    |
| [networking.md](reference/networking.md)       | Bridge/host/none drivers, user-defined networks, service discovery, port publishing          |
| [volumes.md](reference/volumes.md)             | Named volumes vs bind mounts vs tmpfs, when to use each, Compose volume declarations         |
| [security.md](reference/security.md)           | Non-root user, minimal base images, image pinning, .dockerignore, Docker Scout, secrets      |
| [anti-patterns.md](reference/anti-patterns.md) | Severity-labeled anti-patterns to flag in review                                             |

## References

- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/engine/network/
- https://docs.docker.com/engine/storage/

## Maintenance

Docker Engine and Docker Compose release independently. The Compose Specification supersedes the versioned format (version: "3") -- the `version` top-level key is now ignored. Check https://docs.docker.com/engine/release-notes/ for current versions.
