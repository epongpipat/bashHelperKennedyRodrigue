#!/bin/bash

set -e


# ------------------------------------------------------------------------------
# usage function
# ------------------------------------------------------------------------------
usage() {

    cat <<USAGE
    
    Usage: $0 [options]

    Options:
        --study <study> 
            study id (required if available)

        --sub <sub>
            subject id (required if available)

        --ses <1|2|3> 
            wave (required if available)
        
        --task <task>
            task (required if available)

        --run <run>
            run id (required if available)

        --task <task>
            task name (required if available)

        --airc_id, --airc-id <airc_id>    
            airc id (required if available)

        --data_ref, --data-ref <reference>
            reference id (required if available)

        --date <YYYYMMDD>
            date (required if available)

        --overwrite <0|1>
            flag to overwrite output (default: 0/false)

        --print <0|1>
            flag to print command only (does not execute command) (default: 0/false)

        -h, --help
            show this help message and exit
        
USAGE
    # exit 1
}

# ------------------------------------------------------------------------------
# read command line arguments
# ------------------------------------------------------------------------------
parse_args() {
    # if no arguments supplied, show usage
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    # default values
    overwrite=0
    opts=""
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --study)
                study=$2
                opts="${opts} --study ${study}"
                shift 2
                ;;
            --sub)
                sub=$2
                opts="${opts} --sub ${sub}"
                shift 2
                ;;
            --ses)
                wave=$2
                ses=`printf "%02d" ${wave}`
                opts="${opts} --ses ${ses}"
                shift 2
                ;;
            --task)
                task=$2
                opts="${opts} --task ${task}"
                shift 2
                ;;
            --run)
                run=$2
                opts="${opts} --run ${run}"
                shift 2
                ;;
            --task)
                task=$2
                if [[ ${task} == 'nback' ]]; then
                    task_alt='Nback'
                fi
                opts="${opts} --task ${task}"
                shift 2
                ;;
            --airc_id|--airc-id)
                airc_id=$2
                airc_id_number=`echo ${airc_id} | sed 's/3tb//g'`
                opts="${opts} --airc_id ${airc_id}"
                shift 2
                ;;
            --data_ref|--data-ref)
                data_ref=$2
                opts="${opts} --data_ref ${data_ref}"
                shift 2
                ;;
            --date)
                date=$2
                opts="${opts} --date ${date}"
                shift 2
                ;;
            --overwrite)
                overwrite=$2
                opts="${opts} --overwrite ${overwrite}"
                shift 2
                ;;
            --print)
                print=$2
                opts="${opts} --print ${print}"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                usage
                bash error_msg "unknown argument: $1"
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# check required arguments
# ------------------------------------------------------------------------------
check_req_args() {
    for arg in "${args[@]}"; do
        if [[ -z ${!arg} ]]; then
            bash error_msg "missing argument (${arg})"
        fi
    done
}


# ------------------------------------------------------------------------------
# print header
# ------------------------------------------------------------------------------
print_header() {
    echo ""
    echo "date:     $(date)"
    echo "script:   ${0}"
    echo "user:     ${USER}"
    echo "host:     ${HOSTNAME}"
    echo ""
    if [[ ! -z ${study} ]]; then
        echo "study:    ${study}"
    fi
    if [[ ! -z ${sub} ]]; then
        echo "sub:      ${sub}"
    fi
    if [[ ! -z ${ses} ]]; then
        echo "ses:      ${ses}"
    fi
    if [[ ! -z ${task} ]]; then
        echo "task:     ${task}"
    fi
    if [[ ! -z ${run} ]]; then
        echo "run:      ${run}"
    fi
    echo ""
    SECONDS=0
}

# ------------------------------------------------------------------------------
# print footer
# ------------------------------------------------------------------------------
print_footer() {
    echo ""
    echo "date:     $(date)"
    echo "script:   ${0}"
    echo "user:     ${USER}"
    echo "host:     ${HOSTNAME}"
    echo ""
    if [[ ! -z ${study} ]]; then
        echo "study:    ${study}"
    fi
    if [[ ! -z ${sub} ]]; then
        echo "sub:      ${sub}"
    fi
    if [[ ! -z ${ses} ]]; then
        echo "ses:      ${ses}"
    fi
    if [[ ! -z ${task} ]]; then
        echo "task:     ${task}"
    fi
    if [[ ! -z ${run} ]]; then
        echo "run:      ${run}"
    fi
    echo ""
    echo "duration: `get_duration ${SECONDS}`"
    echo ""
}
