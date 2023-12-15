FROM docker.io/node:18

COPY . /source

WORKDIR /source

RUN . /tmp/cachi2.env && yarn install && yarn run build:all

ENTRYPOINT ["yarn", "run", "start"]
