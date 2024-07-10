FROM node:12
ENV YARN_VERSION=1.19.1
RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version ${YARN_VERSION}
