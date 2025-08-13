ARG ALPINE_VERSION=3.22.1
ARG JACRED_VERSION=93c1b7b1291311876dc44738425021d26ccd6e4b
ARG DOTNET_VERSION=8.0

################################################################################
# Builder stage - Fixed directory permission issues
################################################################################
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}-alpine AS build

# Build arguments
ARG TARGETARCH
ARG JACRED_VERSION
ARG BUILDPLATFORM

# Install git and create build infrastructure as root
RUN apk add --no-cache --update \
    git \
    ca-certificates \
    && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Create builduser with proper home directory structure
RUN addgroup -g 10001 -S builduser && \
    adduser -u 10001 -S builduser -G builduser -h /home/builduser -s /bin/sh && \
    mkdir -p /home/builduser/.nuget/packages \
    /home/builduser/.local/share/NuGet \
    /home/builduser/.config/NuGet \
    && chown -R builduser:builduser /home/builduser

# Create output directory with proper permissions BEFORE switching user
RUN mkdir -p /dist && \
    chown builduser:builduser /dist

# Set working directory and ownership
WORKDIR /src
RUN chown builduser:builduser /src

# Switch to builduser with proper environment
USER builduser:builduser

# Set NuGet environment variables
ENV NUGET_PACKAGES=/home/builduser/.nuget/packages \
    DOTNET_CLI_HOME=/home/builduser \
    XDG_CONFIG_HOME=/home/builduser/.config \
    XDG_DATA_HOME=/home/builduser/.local/share

# Git operations
RUN git init . \
    && git remote add origin https://github.com/immisterio/jacred-fdb.git \
    && git fetch --depth 1 origin "$JACRED_VERSION" \
    && git checkout FETCH_HEAD

# Restore packages, build and publish
RUN --mount=type=cache,target=/home/builduser/.nuget/packages,uid=10001,gid=10001,sharing=locked \
    set -eu; \
    case "${TARGETARCH}" in \
    amd64) RID=musl-x64 ;; \
    arm)   RID=musl-arm ;; \
    arm64) RID=musl-arm64 ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    dotnet restore --verbosity minimal || { echo "dotnet restore failed" >&2; exit 1; }; \
    dotnet publish . \
    --os linux \
    -a "$RID" \
    --configuration Release \
    --self-contained true \
    --output /dist \
    --verbosity minimal \
    -p:PublishTrimmed=true \
    -p:PublishSingleFile=true \
    -p:DebugType=None \
    -p:EnableCompressionInSingleFile=true \
    -p:OptimizationPreference=Speed \
    -p:SuppressTrimAnalysisWarnings=true \
    -p:IlcOptimizationPreference=Speed \
    -p:IlcFoldIdenticalMethodBodies=true \
    || { echo "dotnet publish failed" >&2; exit 1; }

################################################################################
# Runtime stage - unchanged
################################################################################
FROM alpine:${ALPINE_VERSION} AS runtime

ARG JACRED_VERSION
ARG BUILDPLATFORM
ARG TARGETARCH

LABEL maintainer="Pavel Pikta <devops@pavelpikta.com>" \
    org.opencontainers.image.title="Jacred" \
    org.opencontainers.image.description="Jacred - Torrent tracker aggregator" \
    org.opencontainers.image.revision="${JACRED_VERSION}"

# Install runtime dependencies and create user
RUN set -eux; \
    apk add --no-cache --update \
    ca-certificates \
    libstdc++ \
    libgcc \
    libintl \
    icu-libs \
    tzdata \
    dumb-init \
    && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* \
    && rm -rf /usr/share/man/* \
    /usr/share/doc/* \
    /usr/share/info/* \
    /usr/share/locale/* \
    && addgroup -g 1000 -S jacred \
    && adduser -u 1000 -S jacred -G jacred -s /sbin/nologin -h /app \
    && mkdir -p /app/Data /app/config \
    && chown -R jacred:jacred /app \
    && chmod -R 750 /app

WORKDIR /app

# Copy application, init configuration, entrypoint
COPY --from=build --chown=jacred:jacred --chmod=550 /dist/ /app/
COPY --chown=jacred:jacred --chmod=640 init.conf /app/init.conf
COPY --chown=jacred:jacred --chmod=550 entrypoint.sh /entrypoint.sh

# Environment variables
ENV JACRED_VERSION="${JACRED_VERSION}" \
    DOTNET_EnableDiagnostics=0 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0 \
    DOTNET_USE_POLLING_FILE_WATCHER=1 \
    ASPNETCORE_URLS=http://0.0.0.0:9117 \
    ASPNETCORE_ENVIRONMENT=Production \
    TZ=UTC \
    UMASK=0027

USER jacred:jacred

VOLUME ["/app/Data", "/app/config"]

EXPOSE 9117/tcp

HEALTHCHECK --interval=30s \
    --timeout=15s \
    --start-period=45s \
    --retries=3 \
    --start-interval=5s \
    CMD wget --quiet \
    --timeout=10 \
    --tries=2 \
    --spider \
    http://127.0.0.1:9117 \
    || exit 1

ENTRYPOINT ["dumb-init", "--", "/entrypoint.sh"]
CMD ["./JacRed"]
