# syntax=docker/dockerfile:experimental
FROM debian:10-slim as build

RUN apt update; \
    apt install -y --no-install-recommends tcpdump unzip libncurses5 python3 python3-pip python3-aiohttp; \
    rm -rf /var/lib/apt/lists/*;

ARG GAME_PORT=16567
ARG STATUS_PORT=27900
ARG GAMESPY_PORT=29900
ARG RCON_PORT=4711
ARG PRISM_PORT=4712

EXPOSE ${GAME_PORT}/udp
EXPOSE ${STATUS_PORT}/udp
EXPOSE ${GAMESPY_PORT}/udp
EXPOSE ${RCON_PORT}/tcp
EXPOSE ${PRISM_PORT}/tcp

WORKDIR /server
COPY entrypoint.sh .

WORKDIR /server/mnt
ENTRYPOINT [ "../entrypoint.sh" ]
