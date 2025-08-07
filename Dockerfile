# Build environment
FROM alpine AS build
RUN apk add --no-cache build-base
WORKDIR /src
COPY . .

# Hardening GCC opts taken from these sources:
# https://developers.redhat.com/blog/2018/03/21/compiler-and-linker-flags-gcc/
# https://security.stackexchange.com/q/24444/204684
ENV CFLAGS=" \
  -static                                 \
  -O2                                     \
  -flto                                   \
  -D_FORTIFY_SOURCE=2                     \
  -fstack-clash-protection                \
  -fstack-protector-strong                \
  -pipe                                   \
  -Wall                                   \
  -Werror=format-security                 \
  -Werror=implicit-function-declaration   \
  -Wl,-z,defs                             \
  -Wl,-z,now                              \
  -Wl,-z,relro                            \
  -Wl,-z,noexecstack                      \
"
RUN make darkhttpd-static \
 && strip darkhttpd-static

# Just the static binary
FROM scratch

# OCI annotations for better package metadata
LABEL org.opencontainers.image.title="DarkHTTPd Static Site"
LABEL org.opencontainers.image.description="Lightweight static web server built with DarkHTTPd, serving static content in a minimal container"
LABEL org.opencontainers.image.vendor="Jason Clark/FG"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/jason-clark-fg/darkhttpd-site"
LABEL org.opencontainers.image.documentation="https://github.com/jason-clark-fg/darkhttpd-site#readme"
LABEL org.opencontainers.image.url="https://github.com/jason-clark-fg/darkhttpd-site"

WORKDIR /var/www/htdocs
COPY --from=build --chown=0:0 /src/darkhttpd-static /darkhttpd
COPY --chown=0:0 passwd /etc/passwd
COPY --chown=0:0 group /etc/group
COPY --chown=0:0 index-typing.html /var/www/htdocs/index.html
EXPOSE 3000
ENTRYPOINT ["/darkhttpd"]
CMD [".", "--chroot", "--port", "3000", "--uid", "nobody", "--gid", "nobody"]
