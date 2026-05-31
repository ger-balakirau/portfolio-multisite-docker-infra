ARG NGINX_VERSION=1.30.1
FROM nginx:${NGINX_VERSION} AS brotli-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    wget \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    NGINX_VERSION="$(nginx -v 2>&1 | sed -n 's#^nginx version: nginx/##p')"; \
    wget -O /tmp/nginx.tar.gz "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"; \
    tar -C /tmp -xzf /tmp/nginx.tar.gz; \
    git clone --recurse-submodules https://github.com/google/ngx_brotli.git /tmp/ngx_brotli; \
    cd /tmp/ngx_brotli/deps/brotli; \
    mkdir -p out; \
    cd out; \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF ..; \
    cmake --build . --config Release -j"$(nproc)"; \
    cd "/tmp/nginx-${NGINX_VERSION}"; \
    ./configure --with-compat --add-dynamic-module=/tmp/ngx_brotli; \
    make modules; \
    mkdir -p /tmp/modules; \
    cp objs/ngx_http_brotli_filter_module.so /tmp/modules/; \
    cp objs/ngx_http_brotli_static_module.so /tmp/modules/

FROM nginx:${NGINX_VERSION}

COPY --from=brotli-builder /tmp/modules/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so
COPY --from=brotli-builder /tmp/modules/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ngx_http_brotli_static_module.so
