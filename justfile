BASE_NAME := "ghcr.io/dimonoff/openvpn-client"
QEMU_BUILDER := "qemu-builder"

default:
  just -l

# Create a builder for multi-arch docker images
setup-builder:
  docker buildx create --name {{QEMU_BUILDER}}

# Build docker images for all artchitectures
build-all:
  #!/usr/bin/env bash
  DOCKERFILE="./Dockerfile.tunnel"
  VERSION=$(grep -i 'FROM alpine' "$DOCKERFILE" | cut -d':' -f2)
  docker buildx build \
    --file "$DOCKERFILE" \
    --builder={{QEMU_BUILDER}} \
    --platform linux/arm64/v8,linux/amd64 \
    --push \
    --tag "{{BASE_NAME}}:${VERSION}-tunnel" .

  DOCKERFILE="./Dockerfile.vpn"
  VERSION=$(grep -i 'FROM alpine' "$DOCKERFILE" | cut -d':' -f2)
  docker buildx build \
    --file "$DOCKERFILE" \
    --builder={{QEMU_BUILDER}} \
    --platform linux/arm64/v8,linux/amd64 \
    --push \
    --tag "{{BASE_NAME}}:${VERSION}" .

# Build docker images for all artchitectures
build-local:
  #!/usr/bin/env bash
  docker build \
    --file ./Dockerfile.tunnel \
    --platform linux/arm64/v8 \
    --tag "localhost:5000/openvpn-tunnel" .
  docker build \
    --file ./Dockerfile.vpn \
    --platform linux/arm64/v8 \
    --tag "localhost:5000/openvpn" .

# Publish a new version 
publish:
  #!/usr/bin/env bash
  set -xe
  TUNNEL_VERSION=$(grep -i 'FROM alpine' ./Dockerfile.tunnel | cut -d':' -f2)
  VPN_VERSION=$(grep -i 'FROM alpine' ./Dockerfile.vpn | cut -d':' -f2)
  if [[ "$TUNNEL_VERSION" != "$VPN_VERSION" ]]; then
    echo "Versions are different: $TUNNEL_VERSION != $VPN_VERSION"
    exit 1
  fi
  VERSION=$TUNNEL_VERSION
  # Check if the tag already exists
  if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "Tag v${VERSION} already exists"
    exit 1
  fi
  git tag -a "v${VERSION}" -m "Release ${VERSION}"
  git push --tags
