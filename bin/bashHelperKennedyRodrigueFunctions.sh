#!/usr/bin/env bash

set -e

declare -a args_order
args_order+=("study")
args_order+=("sub")
args_order+=("ses")
args_order+=("scan")
args_order+=("task")
args_order+=("run")
args_order+=("hemi")
args_order+=("desc")
args_order+=("airc_id")
args_order+=("data_ref")
args_order+=("date")
args_order+=("overwrite")
args_order+=("print")
args_order+=("help")

declare -A help
help[study]="study id"
help[sub]="subject label"
help[ses]="session/wave label"
help[scan]="scan label"
help[task]="task label"
help[run]="run label"
help[hemi]="hemisphere label (L or R)"
help[desc]="description label"
help[airc_id]="airc id"
help[data_ref]="reference id"
help[date]="date (YYYYMMDD)"
help[overwrite]="flag to overwrite output (default: 0/false)"
help[print]="flag to print command only (does not execute command) (default: 0/false)"
help[help]="show this help message and exit"

# ------------------------------------------------------------------------------
# usage function
# ------------------------------------------------------------------------------
usage() {
    help_msg="usage: $0 [options]"
    help_msg="${help_msg}\n\noptions:"
    for key in "${args_order[@]}"; do
        if [[ ${key} =~ '_' ]]; then
            key_alt=`echo ${key} | sed 's/_/-/g'`
            help_msg="${help_msg}\n\n\t--${key}, --${key_alt} <${key}>"
        elif [[ ${key} == "overwrite" ]] || [[ ${key} == "print" ]]; then
            help_msg="${help_msg}\n\n\t--${key} <0|1>"
        else
            help_msg="${help_msg}\n\n\t--${key} <${key}>"
        fi
        help_msg="${help_msg}\n\t\t${help[${key}]}"
    done
    echo -e "${help_msg}\n"
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
    print=0
    
    opts=""
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --study)
                study=$2
                study_uc=`echo ${study} | tr '[:lower:]' '[:upper:]'`
                opts="${opts} --study ${study}"
                shift 2
                ;;
            --sub)
                sub=$2
                opts="${opts} --sub ${sub}"
                shift 2
                ;;
            --ses)
                if [[ ${2} =~ ^[0-9]+$ ]]; then
                    wave=$2
                    ses=`printf "%02d" ${wave}`
                else 
                    ses=$2
                fi
                opts="${opts} --ses ${ses}"
                shift 2
                ;;
            --scan)
                scan=$2
                opts="${opts} --scan ${scan}"
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
            --run)
                run=$2
                opts="${opts} --run ${run}"
                shift 2
                ;;
            --hemi)
                hemi=$2
                if [[ ${hemi} != 'L' ]] && [[ ${hemi} != 'R' ]]; then
                    error_msg "hemi must be L or R"
                fi
                if [[ ${hemi} == 'L' ]]; then
                    hemisphere='left'
                    Hemisphere='Left'
                    hemi_alt='lh'
                    hemi_opposite='R'
                elif [[ ${hemi} == 'R' ]]; then
                    hemisphere='right'
                    Hemisphere='Right'
                    hemi_alt='rh'
                    hemi_opposite='L'
                fi
                opts="${opts} --hemi ${hemi}"
                args_used+=("hemi")
                shift 2
                ;;
            --desc)
                desc=$2
                opts="${opts} --desc ${desc}"
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
                if [[ ! $date =~ ^[0-9]{8}$ ]]; then
                    error_msg "date must be in the format YYYYMMDD"
                fi
                if [[ $date -gt $(date +%Y%m%d) ]]; then
                    error_msg "date must be today's date or a past date"
                fi
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
                error_msg "unknown argument: $1"
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# check required arguments
# ------------------------------------------------------------------------------
check_req_args() {
    local args=(${@})
    local missing_args=()
    for arg in "${args[@]}"; do
        if [[ -z ${!arg} ]]; then
            missing_args+=(${arg})
        fi
    done
    if [[ ${#missing_args[@]} -gt 0 ]]; then
        error_msg "missing required arguments (${missing_args[@]})"
    fi  
}

# ------------------------------------------------------------------------------
# print header
# ------------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "date:\t\t$(date)"
    echo -e "script:\t\t${0}"
    echo -e "user:\t\t${USER}"
    echo -e "host:\t\t${HOSTNAME}"
    echo ""
    for i in ${!args_order[@]}; do
        if [[ -z ${!args_order[$i]} ]]; then
            continue
        fi
        printf "%-10s\t%s\n" ${args_order[$i]}: ${!args_order[$i]}
    done
    echo -e "\n--------------------------------------------------------------------------------\n"
    SECONDS=0
}

# ------------------------------------------------------------------------------
# print footer
# ------------------------------------------------------------------------------
print_footer() {
    echo -e "\n--------------------------------------------------------------------------------\n"
    echo -e "date:\t\t$(date)"
    echo -e "script:\t\t${0}"
    echo -e "user:\t\t${USER}"
    echo -e "host:\t\t${HOSTNAME}"
    echo ""
    for i in ${!args_order[@]}; do
        if [[ -z ${!args_order[$i]} ]]; then
            continue
        fi
        printf "%-10s\t%s\n" ${args_order[$i]}: ${!args_order[$i]}
    done
    echo ""
    echo -e "duration:\t`get_duration ${SECONDS}`"
    echo ""
}

# ------------------------------------------------------------------------------
# get args from idx
# ------------------------------------------------------------------------------
root_dir=`get_root_dir kenrod`
in_path="${root_dir}/software/scripts/eep170030/ids_long-format_study-all.csv"

get_args_from_idx() {
    local idx=`echo ${1}+1 | bc`

    if [ -z ${idx} ]; then
        echo "Usage: get_args_from_idx <idx>"
        exit 1
    fi

    columns=(`cat ${in_path} | head -n 1 | tail -n 1 | tr ',' '\n'`)
    data=(`cat ${in_path} | head -n $idx | tail -n 1 | tr ',' '\n'`)

    for i in `seq 0 $((${#columns[@]}-1))`; do
        eval "${columns[$i]}=${data[$i]}"
    done

    if [[ ! -z ${ses} ]]; then
        if [[ ${ses} =~ ^[0-9]+$ ]]; then
            wave=${ses}
            ses=`printf "%02d" ${ses}`
        fi
    fi

}