FROM brandnewx/ubuntu24:full as base

# Use this image as the platform to build the app
FROM base as build

RUN set -xe && \
  apt-get -yqq update && \
  apt-get install -yq --no-install-recommends \
  build-essential


# The WORKDIR instruction sets the working directory for everything that will happen next
WORKDIR /tmp/node-app

# Copy all local files into the image
COPY . .

# Clean install all node modules
RUN npm ci

# Build app
# RUN npm run build

# Remove dev packages from node_modules
RUN npm ci --omit dev

# Copy files to production directory
RUN mkdir -p /var/node-app/
RUN cp -ar /tmp/node-app/src/. /var/node-app/src
RUN cp -ar /tmp/node-app/node_modules/. /var/node-app/node_modules
RUN cp -a /tmp/node-app/package.json /var/node-app/package.json
RUN cp -a /tmp/node-app/package-lock.json /var/node-app/package-lock.json
RUN cp -ar /tmp/node-app/locales/. /var/node-app/locales
RUN mkdir -p /var/node-app/data

RUN set -xe && \
  usermod -u 1000 www-data 

## Set file permissions
RUN chown -R www-data "/var/node-app" && \
  chmod  +x "/var/node-app/src/index.js"

FROM        base AS release

COPY --from=build /var/node-app/ /var/node-app/

RUN set -xe && \
  usermod -u 1000 www-data 

WORKDIR /var/node-app

USER 1000:1000

ENV NODE_ENV=production
ENV HOST=127.0.0.1
ENV PORT=15071

STOPSIGNAL SIGQUIT
EXPOSE 15071
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD  ["node", "/var/node-app/src/index.js"]
