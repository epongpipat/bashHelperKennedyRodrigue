#!/bin/bash

# ------------------------------------------------------------------------------
# usage function
# ------------------------------------------------------------------------------
usage() {

    cat <<USAGE
    
    Usage: $0 [options]

    Options:
        --sub <sub>
            subject id (required if available)

        --ses <1|2|3> 
            wave (required if available)

        --airc_id <airc_id>    
            airc id (required if available)

        --overwrite <0|1>
            flag to overwrite output (default: 0/false)

        -h, --help
            show this help message and exit
        
USAGE
    exit 1
}

# ------------------------------------------------------------------------------
# read command line arguments
# ------------------------------------------------------------------------------
parse_args() {
    # if no arguments supplied, show usage
    if [ $# -eq 0 ]; then
        usage
    fi

    # default values
    overwrite=0
    opts=""
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
            --airc_id)
                airc_id=$2
                airc_id_number=`echo ${airc_id} | sed 's/3tb//g'`
                opts="${opts} --airc_id ${airc_id}"
                shift 2
                ;;
            --overwrite)
                overwrite=$2
                opts="${opts} --overwrite ${overwrite}"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown argument: $1"
                usage
                ;;
        esac
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
    echo "sub:      ${sub}"
    echo "ses:      ${ses}"
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
    echo "sub:      ${sub}"
    echo "ses:      ${ses}"
    echo ""
    echo "duration: `get_duration ${SECONDS}`"
    echo ""
}