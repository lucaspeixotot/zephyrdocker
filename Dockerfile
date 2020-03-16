# Getting ubuntu image
FROM ubuntu:18.04

# Setting arguments
ARG ZEPHYR_BRANCH=tc_extensor
ARG ZEPHYR_URL=https://github.com/edgebr/zephyr
ARG SDK_VERSION=0.10.0
ARG MY_UID
ARG MY_GID
ARG CMAKE_VERSION=3.16.2

# Setting env variables
ENV ZEPHYR_BASE=/home/appuser/zephyrproject/zephyr
ENV APP=/home/appuser/workdir
ENV DEBIAN_FRONTEND noninteractive

# Creating directories
RUN mkdir -p ${ZEPHYR_BASE}
RUN mkdir -p /opt/toolchains
RUN mkdir -p ${APP}

# Installing packages
RUN dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade

# Installing zephyr dependencias
## Installing default packages
RUN apt-get install -y --no-install-recommends git ninja-build gperf \
  ccache dfu-util wget \
  python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc gcc-multilib g++-multilib libsdl2-dev build-essential

## Installing dtc 1.4.7
RUN wget -q https://launchpad.net/ubuntu/+source/device-tree-compiler/1.4.7-1/+build/15279267/+files/device-tree-compiler_1.4.7-1_amd64.deb && \
        dpkg -i device-tree-compiler_1.4.7-1_amd64.deb 

## Installing Cmake
RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
	rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

## Installing zephyr sdk
RUN wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/zephyr-sdk-${SDK_VERSION}-setup.run" && \
	yes | sh "zephyr-sdk-${SDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${SDK_VERSION} && \
	rm "zephyr-sdk-${SDK_VERSION}-setup.run"

## Installing GCC_ARM
ARG GCC_ARM_NAME=gcc-arm-none-eabi-9-2019-q4-major
RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/${GCC_ARM_NAME}-x86_64-linux.tar.bz2  && \
	tar xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 && \
	rm -f ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 && \
	mv ${GCC_ARM_NAME} /opt/toolchains/${GCC_ARM_NAME}

# Getting zephyr and creating the environment 
#TODO: Ponto de falha por sempre utilizar o requirements do master. Isso foi feito pois em versões antigas do zephyr os requirements estavam quebrados.
RUN git clone -b ${ZEPHYR_BRANCH} --single-branch ${ZEPHYR_URL} ${ZEPHYR_BASE}
RUN pip3 install wheel && \
    wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install -r requirements.txt && \
    rm -f requirements.txt && \
	pip3 install west && \
	pip3 install sh

## Initializing west environment
RUN (cd ${ZEPHYR_BASE}/.. && west init -l ${ZEPHYR_BASE} && west update)

# Download nRF Command Line Tools
RUN wget -qO nrf5_tools.tar.gz https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/nRFCommandLineTools1021Linuxamd64tar.gz

# Extract nRF Command Line Tools
RUN mkdir nrf5_tools
RUN tar -xvzf nrf5_tools.tar.gz -C nrf5_tools

# Install JLink and nRF Command Line Tools
RUN dpkg -i nrf5_tools/JLink_Linux_V644e_x86_64.deb
RUN dpkg -i nrf5_tools/nRF-Command-Line-Tools_10_2_1_Linux-amd64.deb

RUN rm -rf nrf5_tools nrf5_tools.tar.gz

# Creating user and access privilegies
#RUN useradd -r -u $MY_UID -g $MY_GID appuser
#USER appuser

CMD ["/bin/bash"]

WORKDIR ${APP}
VOLUME ${APP}
