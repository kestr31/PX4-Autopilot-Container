ARG BASEIMAGE
ARG BASETAG

#          __                                     __ 
#    _____/ /_____ _____ ____        ____ _____  / /_
#   / ___/ __/ __ `/ __ `/ _ \______/ __ `/ __ \/ __/
#  (__  ) /_/ /_/ / /_/ /  __/_____/ /_/ / /_/ / /_  
# /____/\__/\__,_/\__, /\___/      \__,_/ .___/\__/  
#                /____/                /_/           

# BASE STAGE FOR CACHINE APT PACKAGE LISTS
FROM ${BASEIMAGE}:${BASETAG} as stage_apt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BASETAG

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN \
    if [ "x${BASETAG}" == "x22.04" ] || [ "x${BASETAG}" == "x20.04" ]; then \
        echo "BASE IMAGE CHECK PASSED."; \
    else \
        echo "IMAGE MUST BE BASED ON UBUNTU 20.04 OR 22.04." \
        && exit 1; \
    fi

# SET KAKAO MIRROR FOR FASTER BUILD
# THIS WILL ONLY BE APPLIED ON THE BUILD PROCESS
RUN \
    rm -rf /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
	&& sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
    && apt-get update

# INSTALL DEPENDENCIES FOR ADDING ADDITIONAL REPOS.
RUN \
    apt install -y \
        ca-certificates \
        curl \
        software-properties-common \
        wget

# ADD GAZEBO PACKAGE REPOSITORY
RUN \
    wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
    && apt-get update


#          __                         _____             __
#    _____/ /_____ _____ ____        / __(_)___  ____ _/ /
#   / ___/ __/ __ `/ __ `/ _ \______/ /_/ / __ \/ __ `/ / 
#  (__  ) /_/ /_/ / /_/ /  __/_____/ __/ / / / / /_/ / /  
# /____/\__/\__,_/\__, /\___/     /_/ /_/_/ /_/\__,_/_/   
#                /____/                                   

FROM ${BASEIMAGE}:${BASETAG} as stage_final

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BASETAG

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ADD NON-ROOT USER user AND GRANT SUDO PERMISSION
RUN \
    groupadd user \
    && useradd -ms /bin/zsh user -g user

# UPGRADE THE BASIC ENVIRONMENT FIRST
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
    --mount=type=cache,target=/etc/apt/sources.list,from=stage_apt,source=/etc/apt/sources.list \
	apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        locales \
    && rm -rf /tmp/*

# SET LOCALE TO en_UT.UTF-8
RUN \
    locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# COPY LIST OF APT DEPENDENCIES TO BE INSTALLED
COPY ${BASETAG}/aptDeps.txt /tmp/aptDeps.txt

# INSTALL PACKAGES AVAIABLE BY APT REPOSITORY
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
    --mount=type=cache,target=/etc/apt/sources.list,from=stage_apt,source=/etc/apt/sources.list \
	apt-get install --no-install-recommends -y \
        $(cat /tmp/aptDeps.txt) \
    && rm -rf /tmp/*

# ADD NON-ROOT USER user AND GRANT SUDO PERMISSION
# THIS IS BAD FOR CONTAINER SECURITY
# BUT THIS DOES NOT MATTERS FOR DEVELOPING SIMULATOR CONTAINER
RUN \
    echo "user ALL=NOPASSWD: ALL" >> /etc/sudoers

# CHANGE USER TO NEWLY GENERATED user AND CHANGE WORKING DIRECTORY TO user's HOME
USER user
WORKDIR /home/user

# FOR EASE OF DEVELOPMENT, INSTALL OH-MY-ZSH AND PLUGINS. SET ALIAS FOR CAT
RUN \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended \
    && sed -i "s/robbyrussell/agnoster/g" ${HOME}/.zshrc \
    && git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        ${HOME}/.oh-my-zsh/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${HOME}/.oh-my-zsh/plugins/zsh-syntax-highlighting \
    && sed -i "s/(git)/(git zsh-autosuggestions zsh-syntax-highlighting)/g" ${HOME}/.zshrc \
    && echo "alias cat='batcat --paging=never'" >> ${HOME}/.zshrc

# CLONE PX4-AUTOPILOT REPOSITORY AND GET ALL SUBMODULES
# THEN, INSTALL DEPENDENCIES REQUIRED FOR THE DEVELOPMENT
RUN \
    git clone https://github.com/PX4/PX4-Autopilot.git -b v1.14.0 \
    && git -C PX4-Autopilot submodule update --init --recursive \
    && PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools \
    && sudo apt-get autoremove -y \
    && sudo apt-get clean autoclean \
    && sudo rm -rf /var/cache/apt/archives /var/lib/apt/lists/* \
    # EMPY UPDATE, NOVEMBER 30.
    && pip uninstall em \
    && pip install empy==3.3.4

RUN \
    cd /home/user/PX4-Autopilot/src/modules/uxrce_dds_client && \
    sed -i '23s%.*%  - topic: /fmu/out/vehicle_angular_velocity%g' dds_topics.yaml  && \
    sed -i '24s%.*%    type: px4_msgs::msg::VehicleAngularVelocity%g' dds_topics.yaml 

# COPY PATCH FILE TO FIX HOME LLA SETTING ISSUE
COPY --chown=user:user fixes/fixHomeLLASet /tmp/fixHomeLLASet

# BUILD PX4 SITL FIRMWARE TO BE INCLUDED
RUN \
    # FROM COMMIT 2D78383: GAZEBO HARMONIC SUPPORT
    # FROM COMMIT 18334b8: FIXING GAZEBO HOME LLA SETUP
    sed -i '80r /tmp/fixHomeLLASet' \
        /home/user/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/px4-rc.simulator \
    && if [[ "x${BASETAG}" == "x22.04" ]]; then \
            sed -i 's/gz-transport12/gz-transport13/g' \
                PX4-Autopilot/src/modules/simulation/gz_bridge/CMakeLists.txt \
            && sed -i '38i #include <gz/msgs.hh>' \
                /home/user/PX4-Autopilot/src/modules/simulation/gz_bridge/GZMixingInterfaceESC.hpp \
            && make -C /home/user/PX4-Autopilot px4_sitl; \
        elif [[ "x${BASETAG}" == "x20.04" ]]; then \
            cp /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.sh \
                /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.bak \
            && echo 'echo "THERE IS NOTHING."' > /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.sh \
            && make -C /home/user/PX4-Autopilot px4_sitl gazebo-classic \
            && mv /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.bak \
                /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.sh \
            && rm -rf /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_run.bak; \
        else \
            echo "IMAGE MUST BE BASED ON UBUNTU 20.04 OR 22.04" \
            && exit 1; \
        fi

# ENTRYPOINT SCRIPT
# SET PERMISSION SO THAT USER CAN EDIT INSIDE THE CONTAINER
COPY --chown=user:user ${BASETAG}/entrypoint.sh /usr/local/bin/entrypoint.sh

# CREATE SYMBOLIC LINK FOR QUICK ACCESS
RUN \
    mkdir /home/user/scripts \
    && sudo ln -s /usr/local/bin/entrypoint.sh /home/user/scripts/entrypoint.sh

CMD [ "/usr/local/bin/entrypoint.sh" ]

# ------ BUILD COMMAND(FOCAL) ------
# DOCKER_BUILDKIT=1 docker build \
# --build-arg BASEIMAGE=ubuntu \
# --build-arg BASETAG=20.04 \
# -t jociiiii/px4:dev-1.14.0-focal-0.0.1 \
# -f ./Dockerfile .

# ------ BUILD COMMAND(JAMMY) ------
# DOCKER_BUILDKIT=1 docker build \
# --build-arg BASEIMAGE=ubuntu \
# --build-arg BASETAG=22.04 \
# -t jociiiii/px4:dev-1.14.0-jammy-0.0.1 \
# -f ./Dockerfile .