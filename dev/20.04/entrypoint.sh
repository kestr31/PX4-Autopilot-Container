#! /bin/bash

debug_message() {
    echo "
        ____  __________  __  ________   __  _______  ____  ______
       / __ \/ ____/ __ )/ / / / ____/  /  |/  / __ \/ __ \/ ____/
      / / / / __/ / __  / / / / / __   / /|_/ / / / / / / / __/   
     / /_/ / /___/ /_/ / /_/ / /_/ /  / /  / / /_/ / /_/ / /___   
    /_____/_____/_____/\____/\____/  /_/  /_/\____/_____/_____/   
    
    "
    echo "INFO [SITL] DEBUG_MODE IS SET. NOTHING WILL RUN"
}


# DIRECTORY TO PX4-AutoPilot SOURCE
PX4_SRC_DIR=/home/user/PX4-Autopilot


## DESIGNATE QGC ADDRESS TO ALLOW BROADCASTING MAVLINK SIGNAL
if [ ! -z "${QGC_IP}" ]; then 
    sed -i "s/-x -u \$udp_gcs_port_local/-x -t ${QGC_IP} -u \$udp_gcs_port_local/g" \
        ${PX4_SRC_DIR}/build/px4_sitl_default/etc/init.d-posix/px4-rc.mavlink
fi

## DESIGNATE ROS2 UXRCE AGENT IP TO ALLOW COMMUNICATE ROS2 TOPIC
if [ ! -z "${ROS2_UXRCE_IP}" ]; then
    sed -i "s/-h 127.0.0.1/-h ${ROS2_UXRCE_IP}/g" \
        ${PX4_SRC_DIR}/build/px4_sitl_default/etc/init.d-posix/rcS
    export UXRCE_DDS_AG_IP=$(python3 ${PX4_SRC_DIR}/Tools/convert_ip.py ${ROS2_UXRCE_IP})
fi


# A. INITIALIZATION SCRIPT MODIFIER
## CASE A-1. gazebo SIMULATION
if [ "${SITL_TYPE}" = "gazebo" ]; then

    ## A-1. CHECK IF PREVIOUS BUILD EXISTS OR NOT
    ### CASE A-1-1. PREVIOUS BUILD EXISTS
    if [ -d "${PX4_SRC_DIR}/build" ]; then

        echo "INFO [SITL] PREVIOUS BUILD EXISTS!"
        SITL_rcS_DIR=${PX4_SRC_DIR}/build/px4_sitl_default/etc/init.d-posix

    ### CASE A-1-2. NOTHING WAS BUILD BEFORE
    else

        echo "INFO [SITL] NO BUILD EXISTS!"
        SITL_rcS_DIR=${PX4_SRC_DIR}/ROMFS/px4fmu_common/init.d-posix

    fi

    #- COMMENT-OUT PROBLEMATIC/REDUNDANT LINES FROM gazebo rcS SCRIPT
    COMMENT_START=$(grep -wn "if \[ -f ./gz_env.sh \]; then" ${SITL_rcS_DIR}/px4-rc.simulator | cut -d: -f1)
    COMMENT_END=$(grep -wn "gazebo already running world: \${gz_world}" ${SITL_rcS_DIR}/px4-rc.simulator | cut -d: -f1)

    COMMENT_START=$(($COMMENT_START - 1))
    COMMENT_END=$(($COMMENT_END + 2))

    sed -i "${COMMENT_START},${COMMENT_END}s/\(.*\)/#\1/g" \
        ${SITL_rcS_DIR}/px4-rc.simulator

## CASE A-2. gazebo-classic SIMULATION [ERROR]
elif [ "${SITL_TYPE}" = "gazebo-classic" ]; then

    COMMENT_START=$(grep -wn 'if [ "\$debugger" == "lldb" ]; then' ${PX4_SRC_DIR}/Tools/simulation/gazebo-classic/sitl_run.sh | cut -d: -f1)
    COMMENT_END=$(grep -wn 'kill -9 \$SIM_PID' ${PX4_SRC_DIR}/Tools/simulation/gazebo-classic/sitl_run.sh | cut -d: -f1)

    COMMENT_START=$(($COMMENT_START - 1))
    COMMENT_END=$(($COMMENT_END + 3))

## CASE A-3. NO SIMULATION DESIGNATED [ERROR]
else
    echo "ERROR [SITL] NO \${SITL_TYPE} DESIGNATED"
    exit 1
fi


# B. DEBUG MODE / SIMULATION SELCTOR
## CASE B-1: DEBUG MODE
if [ "${DEBUG_MODE}" -eq "1" ]; then

    debug_message

    ## B-1. EXPORT ENVIRONMENT VARIABLE?
    ### CASE B-1-1: YES EXPORT THEM
    if [ "${EXPORT_ENV}" -eq "1" ]; then

        #- GET LINE NUMBER TO START ADDING export STATEMENT
        COMMENT_BASH_START=$(grep -c "" /home/user/.bashrc)
        COMMENT_ZSH_START=$(grep -c "" /home/user/.zshrc)

        COMMENT_BASH_START=$(($COMMENT_BASH_START + 1))
        COMMENT_ZSH_START=$(($COMMENT_ZSH_START + 1))

        ### B-1-1. SIMULATION TYPE SELECTOR
        #### CASE B-1-1-1: gazebo SIMULATION
        if [ "${SITL_TYPE}" = "gazebo" ]; then

            #- WTIE VARIABLES TO BE EXPORTED TO THE TEMPFILE
            echo "DEBUG_MODE=0" >> /tmp/envvar
            echo "PX4_SYS_AUTOSTART=${SITL_AIRFRAME_ID}" >> /tmp/envvar
            echo "PX4_GZ_MODEL=${SITL_AIRFRAME}" >> /tmp/envvar
            echo "PX4_GZ_MODEL_POSE=${SITL_POSE}" >> /tmp/envvar

        #### CASE B-1-1-2: gazebo-classic SIMULATION [ERROR]
        elif [ "${SITL_TYPE}" = "gazebo-classic" ]; then

            #- WTIE VARIABLES TO BE EXPORTED TO THE TEMPFILE
            echo "DEBUG_MODE=0" >> /tmp/envvar
            echo "PX4_SYS_AUTOSTART=${SITL_AIRFRAME_ID}" >> /tmp/envvar

        #### CASE B-1-1-3: NO SIMULATION DESIGNATED [ERROR]
        else

            echo "ERROR [SITL] NO \${SITL_TYPE} DESIGNATED"
            exit 1
            
        fi

        echo "INFO [SITL] ENVIRONMENT VARS FOR SITL WILL BE EXPORTED"

        #- ADD VARIABLES TO BE EXPORTED TO SHELL RC
        for value in $(cat /tmp/envvar)
        do
            echo ${value} >> /home/user/.bashrc
            echo ${value} >> /home/user/.zshrc
        done

        #- ADD export STATEMENT TO VARIABLES
        sed -i "${COMMENT_BASH_START},\$s/\(.*\)/export \1/g" \
            ${HOME}/.bashrc
        sed -i "${COMMENT_ZSH_START},\$s/\(.*\)/export \1/g" \
            ${HOME}/.zshrc

        #- REMOVE TEMPORARY FILE
        rm -f /tmp/envvar

    ### CASE B-1-2: NO LEAVE THEM CLEAN
    else
        echo "INFO [SITL] ENVIRONMENT VARS WILL NOT BE SET"
    fi


## CASE B-2: SIMULATION MODE
else
    
    ## B-2. SIMULATION TYPE SELECTOR
    ### CASE B-2-1: gazebo SIMULATION
    if [ "${SITL_TYPE}" = "gazebo" ]; then

        echo "INFO [SITL] RUNNING ${SITL_TYPE} SITL"

        PX4_SYS_AUTOSTART=${SITL_AIRFRAME_ID} \
        PX4_GZ_MODEL=${SITL_AIRFRAME} \
        PX4_GZ_MODEL_POSE=${SITL_POSE} \
        ${PX4_SRC_DIR}/build/px4_sitl_default/bin/px4 -d

    ### CASE B-2-2: gazebo-classic SIMULATION [ERROR]
    elif [ "${SITL_TYPE}" = "gazebo-classic" ]; then

        echo "INFO [SITL] RUNNING ${SITL_TYPE} SITL"

        PX4_SYS_AUTOSTART=${SITL_AIRFRAME_ID} \
        ${PX4_SRC_DIR}/build/px4_sitl_default/bin/px4 -d

    ### CASE B-2-3: NO SIMULATION DESIGNATED [ERROR]
    else

        echo "ERROR [SITL] NO \${SITL_TYPE} DESIGNATED"
        exit 1
        
    fi
fi

# KEEP CONTAINER ALIVE
sleep infinity