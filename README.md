# CONTAINERIZED PX4 FLIGHT SOFTWARE FOR PX4 SITL

## 0. OVERVIEW

- Further documentation will be done.

## 1. AVAIABLE TAGS & BUILD ORDERS

- TBD

## 2. ENVIRONMENT VARIABLE SETUPS

- TBD

## 3. HOW-TO-BUILD

### 3.1. `dev-1.14.0-focal`

```shell
DOCKER_BUILDKIT=1 docker build \
--build-arg BASEIMAGE=ubuntu \
--build-arg BASETAG=20.04 \
-t kestr3l/px4:dev-1.14.0-focal \
-f ./dev/Dockerfile ./dev
```

### 3.2. `dev-1.14.0-jammy`

```shell
DOCKER_BUILDKIT=1 docker build \
--build-arg BASEIMAGE=ubuntu \
--build-arg BASETAG=22.04 \
-t kestr3l/px4:dev-1.14.0-jammy \
-f ./dev/Dockerfile ./dev
```

### 3.3. `run-1.14.0`

```shell
DOCKER_BUILDKIT=1 docker build \
--build-arg BASEIMAGE=ubuntu \
--build-arg BASETAG=22.04 \
-t kestr3l/px4:run-1.14.0 \
-f ./run/Dockerfile ./run
```

## 4. ATTACHING CONTAINER TO SITL

- TBD