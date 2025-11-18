# ----- Builder stage -----
FROM rust:latest as builder

WORKDIR /app

RUN apt-get update && apt-get install -y musl-tools && \
    rustup target add x86_64-unknown-linux-musl

# Create a blank project
RUN cargo init

# Copy manifest first (for dependency caching)
COPY Cargo.toml Cargo.lock .

# Create a dummy src/main.rs so `cargo build` succeeds for dependency caching
#RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies only
RUN cargo build --release --target x86_64-unknown-linux-musl || true

# Now copy the actual source
COPY . .

# Read the binary name from Cargo.toml
# This outputs: example-app, myapp, backend-api, etc.
RUN BIN_NAME=$(sed -n 's/^name\s*=\s*"\(.*\)"/\1/p' Cargo.toml) && \
    echo $BIN_NAME > /bin_name

# Build real binary
RUN cargo build --release --target x86_64-unknown-linux-musl

# ----- Runtime stage -----
FROM alpine AS runtime

WORKDIR /app

# Load binary name determined in builder stage
COPY --from=builder /bin_name /bin_name
RUN BIN_NAME=$(cat /bin_name) && echo "Binary name: $BIN_NAME"

# Copy compiled binary
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/ /app/

# Default command (binary name detected dynamically)
CMD ["/bin/sh", "-c", "/app/$(cat /bin_name)"]
