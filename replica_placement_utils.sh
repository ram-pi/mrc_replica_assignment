#!/bin/bash

SCRIPT_TOPIC_FILE_NAME=(${PWD}/all_topics.txt)
EXECUTION_TOPIC_FILE_NAME=(${PWD}/without_placement.txt)
EXECUTION_MODE=false

show_usage() {
    echo "Usage: $0 [options [parameters]]"
    echo ""
    echo "Options:"
    echo "    --help -- Prints this page"
    echo "    --list-topics -- Produce 2 different files. all_topics.txt and without_placement.txt"
    echo "    --bootstrap-server [bootstrap-server-list]"
    echo "    --command-config [command-config-file]"
    echo "    --replica-placement-filepath [replica-placement-filepath]"
    echo "    --topics-filepath [topics-filepath default: without_placement.txt]"

    echo "Examples:"
    echo "    ./replica_placement_utils.sh --bootstrap-server localhost:9092 --list-topic"
    echo "    ./replica_placement_utils.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.json  --execute --topics-filepath execution.txt"
    echo "    ./replica_placement_utils.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.json  --execute --topics-filepath execution.txt --command-config client.config"

    return 0
}

show_dislaimer() {
    echo "============================================================================"
    echo "Ensure that all the topics are listed execution file (default: without_placement.txt). If some topics are missing, the current user provided in the command config does not have full permissions."
    echo "If Confluent RBAC is enabled, ensure that the user is SystemAdmin to allow all necessary operations."
    echo "============================================================================"
    echo "This script does not validate the Replica placement file for correctness. Please ensure that the file is correct before apply the replica placement."
}

list_topics() {
    echo "Fetching the list of topics to ensure that all settings are working properly"
    echo "============================================================================"
    if [[ -z "${SCRIPT_COMMAND_CONFIG}" ]]; then
        echo "Executing without Command Config"
        kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --list >${SCRIPT_TOPIC_FILE_NAME}
    else
        echo "Executing with Command Config"
        kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --command-config ${SCRIPT_COMMAND_CONFIG} --list >${SCRIPT_TOPIC_FILE_NAME}
    fi

    # if [[ "$ONLY_DESCRIBE_TOPICS" == true ]]; then
    #     echo "============================================================================"
    #     echo "Describing all topics"
    #     cat ${SCRIPT_TOPIC_FILE_NAME} | while read topic_name; do
    #         if [[ -z "${SCRIPT_COMMAND_CONFIG}" ]]; then
    #             echo "Executing without Command Config"
    #             kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --topic ${topic_name} --describe
    #         else
    #             echo "Executing with Command Config"
    #             kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --command-config ${SCRIPT_COMMAND_CONFIG} --topic ${topic_name} --describe
    #         fi
    #     done
    #     rm ${SCRIPT_TOPIC_FILE_NAME}
    #     echo "============================================================================"
    #     exit 0
    # fi

    cat ${SCRIPT_TOPIC_FILE_NAME} | while read topic_name; do
        echo "======================"
        echo "Checking ${topic_name}"
        if [[ -z "${SCRIPT_COMMAND_CONFIG}" ]]; then
            OUTPUT_TOPIC_NAME=$(kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --topic ${topic_name} --describe | grep "Configs:" | grep -v "confluent.placement.constraints={" | awk '{print $2}')
        else
            OUTPUT_TOPIC_NAME=$(kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --command-config ${SCRIPT_COMMAND_CONFIG} --topic ${topic_name} --describe | grep "Configs:" | grep -v "confluent.placement.constraints={" | awk '{print $2}')
        fi
        if [[ -z "$OUTPUT_TOPIC_NAME" ]]; then
            echo "topic ${topic_name} already has MRC configs. Skipping"
        else
            echo "topic ${topic_name} does not have MRC configs. Update necessary."
            echo "Adding to execution list."
            echo ${OUTPUT_TOPIC_NAME} >>${EXECUTION_TOPIC_FILE_NAME}
        fi
    done
    echo "============================================================================"
    echo "The output of this step are available in ${EXECUTION_TOPIC_FILE_NAME} and ${SCRIPT_TOPIC_FILE_NAME}"
    echo "Validation complete. Check and remove the topics that you would not like to enable for MRC from the file."
    echo "============================================================================"
    exit 0
}

execute() {
    echo "============================================================================"
    echo "Execution file is: ${EXECUTION_TOPIC_FILE_NAME}"

    cat ${EXECUTION_TOPIC_FILE_NAME} | while read topic_name; do
        echo "Working on ${topic_name}"
        if [[ -z "${SCRIPT_COMMAND_CONFIG}" ]]; then
            echo "Executing without Command Config"
            kafka-configs --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --entity-type topics --entity-name ${topic_name} --alter --replica-placement ${SCRIPT_REPLICA_PLACEMENT_FILE_NAME}
        else
            echo "Executing with Command Config"
            kafka-configs --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --command-config ${SCRIPT_COMMAND_CONFIG} --entity-type topics --entity-name ${topic_name} --alter --replica-placement ${SCRIPT_REPLICA_PLACEMENT_FILE_NAME}
        fi
        echo "============================================"
    done
    echo "============================================================================"
    echo "Done"
    echo "============================================================================"

    echo "Do you want me to describe all the topics for sanity [y/n]?"
    read SCRIPT_DESCRIBE_READ
    if [[ "$SCRIPT_DESCRIBE_READ" == "y" ]] || [[ "$SCRIPT_DESCRIBE_READ" == "Y" ]] || [[ "$SCRIPT_DESCRIBE_READ" == "yes" ]] || [[ "$SCRIPT_DESCRIBE_READ" == "YES" ]]; then
        cat ${EXECUTION_TOPIC_FILE_NAME} | while read topic_name; do
            if [[ -z "${SCRIPT_COMMAND_CONFIG}" ]]; then
                echo "Executing without Command Config"
                kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --topic ${topic_name} --describe
            else
                echo "Executing with Command Config"
                kafka-topics --bootstrap-server ${SCRIPT_BOOTSTRAP_SERVERS} --command-config ${SCRIPT_COMMAND_CONFIG} --topic ${topic_name} --describe
            fi
            echo "============================================"
        done
    fi

    # rm ${SCRIPT_TOPIC_FILE_NAME} ${EXECUTION_TOPIC_FILE_NAME}
    exit 0
}

if [[ $# -eq 0 ]]; then
    echo "No input arguments provided."
    show_usage
    exit 1
fi

echo "============================================================================"
LIST_TOPICS_ENABLED=false

while [ ! -z "$1" ]; do
    if [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    elif [[ "$1" == "--bootstrap-server" ]]; then
        if [[ "$2" == --* ]] || [[ -z "$2" ]]; then
            echo "No Value provided for "$1". Please ensure proper values are provided"
            show_usage
            exit 1
        fi
        SCRIPT_BOOTSTRAP_SERVERS="$2"
        echo "Bootstrap Servers are: ${SCRIPT_BOOTSTRAP_SERVERS}"
        shift
    elif [[ "$1" == "--command-config" ]]; then
        if [[ "$2" == --* ]] || [[ -z "$2" ]]; then
            echo "No Value provided for "$1". Please ensure proper values are provided"
            show_usage
            exit 1
        fi
        SCRIPT_COMMAND_CONFIG="$2"
        echo "Command Config File path is: ${SCRIPT_COMMAND_CONFIG}"
        shift
    elif [[ "$1" == "--replica-placement-filepath" ]]; then
        if [[ "$2" == --* ]] || [[ -z "$2" ]]; then
            echo "No Value provided for "$1". Please ensure proper values are provided"
            show_usage
            exit 1
        fi
        SCRIPT_REPLICA_PLACEMENT_FILE_NAME="$2"
        echo "Replica Placement file is: ${SCRIPT_REPLICA_PLACEMENT_FILE_NAME}"
        shift
    elif [[ "$1" == "--list-topics" ]]; then
        LIST_TOPICS_ENABLED=true
        echo "List topics is currently enabled"
    elif [[ "$1" == "--execute" ]]; then
        EXECUTION_MODE=true
        echo "Execution mode currently enabled"
    elif [[ "$1" == "--topics-filepath" ]]; then
        EXECUTION_TOPIC_FILE_NAME="$2"
    fi
    shift
done

if [[ -z "$SCRIPT_BOOTSTRAP_SERVERS" ]]; then
    echo "--bootstrap-server is required for execution."
    show_usage
    exit 1
fi

if [[ "$LIST_TOPICS_ENABLED" = false ]] && [[ -z "$SCRIPT_REPLICA_PLACEMENT_FILE_NAME" ]]; then
    echo "--list-topics or --replica-placement-filepath are required for execution."
    show_usage
    exit 1
fi

if [[ "$LIST_TOPICS_ENABLED" = true ]]; then
    list_topics
    exit 1
fi

if [[ "$EXECUTION_MODE" = true ]]; then
    show_dislaimer
    execute
    exit 1
fi
