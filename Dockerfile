# Use a base image with the latest version of Rust installed
FROM rust:latest as builder

ARG CRATE_NAME=rust_musl_dylib_example

# Set the working directory in the container
WORKDIR /app

# Install the linux-musl build target
RUN rustup target add x86_64-unknown-linux-musl

# Create a blank project
RUN cargo init --lib

# Copy only the dependencies
COPY Cargo.toml Cargo.lock ./

# A dummy build to get the dependencies compiled and cached
RUN cargo build --target x86_64-unknown-linux-musl --release

# Copy the real application code into the container
COPY . .

# Build the application
RUN cargo build --target x86_64-unknown-linux-musl --release

# (Optional) Remove debug symbols
ENV SO_FILE=target/x86_64-unknown-linux-musl/release/lib$CRATE_NAME.so
RUN strip $SO_FILE

# Use a slim image for running the application
FROM alpine as runtime

# Install the binutils package to get the nm command
RUN apk add binutils

ARG OUTLIB=libexample.so

# Copy only the compiled binary from the builder stage to this image
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/*.so $OUTLIB

ENV OUTLIB=$OUTLIB
# nm displays the symbols in the library
# CMD echo "Running 'nm -D $OUTLIB':" && nm -D $OUTLIB
CMD echo "Running `nm -D $OUTLIB | grep 'hello'`:" && nm -D $OUTLIB | grep 'hello'
