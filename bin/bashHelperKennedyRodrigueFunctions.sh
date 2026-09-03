#!/usr/bin/env bash

set -e

declare -a args_order
args_order+=("lab")
args_order+=("study")
args_order+=("sub")
args_order+=("ses")
args_order+=("scan")
args_order+=("task")
args_order+=("acq")
args_order+=("run")
args_order+=("hemi")
args_order+=("space")
args_order+=("seg")
args_order+=("res")
args_order+=("label")
args_order+=("desc")
args_order+=("airc_id")
args_order+=("data_ref")
args_order+=("date")
args_order+=("visit_type")
args_order+=("visit_number")
args_order+=("overwrite")
args_order+=("print")
args_order+=("help")

declare -A help
help[lab]="lab name (e.g., kenrod, kennedy, rodrigue)"
help[study]="study id"
help[sub]="subject label"
help[ses]="session/wave label"
help[scan]="scan label"
help[task]="task label"
help[acq]="acquisition label"
help[run]="run label"
help[hemi]="hemisphere label (L or R)"
help[space]="space label (e.g., MNI152NLin6Sym)"
help[seg]="segmentation label"
help[res]="resolution label"
help[label]="label for the segmentation"
help[desc]="description label"
help[airc_id]="airc id"
help[data_ref]="reference id"
help[date]="date (YYYYMMDD)"
help[visit_type]="visit type"
help[visit_number]="visit number"
help[overwrite]="flag to overwrite output (default: 0/false)"
help[print]="flag to print command only (does not execute command) (default: 0/false)"
help[help]="show this help message and exit"

# ------------------------------------------------------------------------------
# usage function
# ------------------------------------------------------------------------------
usage() {
    # Normalize args_req to an array for checking
    local req_array=()
    if declare -p args_req 2>/dev/null | grep -q 'declare -a'; then
        req_array=("${args_req[@]}")
    else
        req_array=(${args_req})
    fi

    # Classify keys into required and optional
    local req_keys=()
    local opt_keys=()
    for key in "${args_order[@]}"; do
        local is_req=0
        for req in "${req_array[@]}"; do
            if [[ ${req} == "${key}" ]]; then
                is_req=1
                break
            fi
        done
        if [[ ${is_req} -eq 1 ]]; then
            req_keys+=("${key}")
        else
            opt_keys+=("${key}")
        fi
    done

    # Build the argparse-style usage line
    local usage_line="usage: $(basename "$0") [-h]"
    
    # Optional arguments
    for key in "${opt_keys[@]}"; do
        if [[ ${key} == "help" ]]; then
            continue
        fi
        local key_kebab=$(echo "${key}" | sed 's/_/-/g')
        local key_upper=$(echo "${key}" | tr '[:lower:]' '[:upper:]')
        if [[ ${key} == "overwrite" || ${key} == "print" ]]; then
            usage_line="${usage_line} [--${key_kebab} <0|1>]"
        else
            usage_line="${usage_line} [--${key_kebab} ${key_upper}]"
        fi
    done

    # Required arguments
    for key in "${req_keys[@]}"; do
        if [[ ${key} == "help" ]]; then
            continue
        fi
        local key_kebab=$(echo "${key}" | sed 's/_/-/g')
        local key_upper=$(echo "${key}" | tr '[:lower:]' '[:upper:]')
        if [[ ${key} == "overwrite" || ${key} == "print" ]]; then
            usage_line="${usage_line} --${key_kebab} <0|1>"
        else
            usage_line="${usage_line} --${key_kebab} ${key_upper}"
        fi
    done

    # Build the help message starting with the description if present
    local help_msg=""
    if [[ -n ${args_description} ]]; then
        help_msg="description:\n\t${args_description}\n\n"
    fi
    help_msg="${help_msg}${usage_line}"

    # Print Required Section if present
    if [[ ${#req_keys[@]} -gt 0 ]]; then
        help_msg="${help_msg}\n\nrequired options:"
        for key in "${req_keys[@]}"; do
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

        help_msg="${help_msg}\n\noptional options:"
    else
        help_msg="${help_msg}\n\noptions:"
    fi

    # Print Optional Section
    for key in "${opt_keys[@]}"; do
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

parse_args() {
    # Pre-scan for args_req and args_description so they are available to usage() if --help is called
    local i
    for ((i=1; i<=$#; i++)); do
        if [[ ${!i} == "--args-req" ]]; then
            unset args_req
            local j=$((i+1))
            local req_list=()
            while [[ ${j} -le $# ]] && [[ ${!j} != --* ]]; do
                req_list+=("${!j}")
                j=$((j+1))
            done
            args_req="${req_list[*]}"
        elif [[ ${!i} == "--args-description" ]]; then
            unset args_description
            local j=$((i+1))
            local desc_list=()
            while [[ ${j} -le $# ]] && [[ ${!j} != --* ]]; do
                desc_list+=("${!j}")
                j=$((j+1))
            done
            args_description="${desc_list[*]}"
        fi
    done

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
            -h|--help)
                usage
                exit 0
                ;;
            --args-req)
                shift
                while [[ $# -gt 0 ]] && [[ $1 != --* ]]; do
                    shift
                done
                ;;
            --args-description)
                shift
                while [[ $# -gt 0 ]] && [[ $1 != --* ]]; do
                    shift
                done
                ;;
            --*)
                # Strip leading --
                local key=${1#--}
                # Convert dashes to underscores (e.g., data-ref -> data_ref)
                local var_name=${key//-/_}
                
                # Check if var_name is in args_order
                local is_valid=0
                local order_key
                for order_key in "${args_order[@]}"; do
                    if [[ ${order_key} == "${var_name}" ]]; then
                        is_valid=1
                        break
                    fi
                done
                if [[ ${is_valid} -eq 1 ]]; then
                    # Check if value is missing (no arguments left or next starts with --)
                    if [[ $# -lt 2 ]] || [[ $2 == --* ]]; then
                        usage
                        error_msg "option $1 requires an argument"
                    fi
                    local val=$2
                    
                    # Store the value
                    eval "${var_name}=\$val"
                    
                    # Special validation/processing logic
                    case "${var_name}" in
                        lab)
                            lab_uc=$(echo "${val}" | tr '[:lower:]' '[:upper:]')
                            ;;
                        study)
                            study_uc=$(echo "${val}" | tr '[:lower:]' '[:upper:]')
                            ;;
                        sub)
                            sub_uc=$(echo "${val}" | tr '[:lower:]' '[:upper:]')
                            ;;
                        ses)
                            if [[ ${val} =~ ^[0-9]+$ ]]; then
                                wave=${val}
                                ses=$(printf "%02d" "${wave}")
                            else 
                                ses=${val}
                            fi
                            # Update the evaluated variable in case we formatted it
                            eval "${var_name}=\$ses"
                            ;;
                        task)
                            if [[ ${val} == 'nback' ]]; then
                                task_alt='Nback'
                            fi
                            ;;
                        hemi)
                            if [[ ${val} != 'L' ]] && [[ ${val} != 'R' ]]; then
                                error_msg "hemi must be L or R"
                            fi
                            if [[ ${val} == 'L' ]]; then
                                hemisphere='left'
                                Hemisphere='Left'
                                hemi_alt='lh'
                                hemi_opposite='R'
                            elif [[ ${val} == 'R' ]]; then
                                hemisphere='right'
                                Hemisphere='Right'
                                hemi_alt='rh'
                                hemi_opposite='L'
                            fi
                            args_used+=("hemi")
                            ;;
                        airc_id)
                            airc_id_number=$(echo "${val}" | sed 's/3tb//g' | sed 's/7t//g')
                            airc_id_uc=$(echo "${val}" | tr '[:lower:]' '[:upper:]')
                            ;;
                        date)
                            if [[ ! $val =~ ^[0-9]{8}$ ]]; then
                                error_msg "date must be in the format YYYYMMDD"
                            fi
                            if [[ $val -gt $(date +%Y%m%d) ]]; then
                                error_msg "date must be today's date or a past date"
                            fi
                            date_mmddyyyy="${val:4:4}${val:0:4}"
                            ;;
                        overwrite)
                            if [[ ${val} != "0" && ${val} != "1" ]]; then
                                error_msg "overwrite must be 0 or 1"
                            fi
                            ;;
                        print)
                            if [[ ${val} != "0" && ${val} != "1" ]]; then
                                error_msg "print must be 0 or 1"
                            fi
                            ;;
                    esac
                    
                    # Fetch resolved/potentially updated value
                    eval "local resolved_val=\${${var_name}}"
                    opts="${opts} --${var_name} ${resolved_val}"
                    shift 2
                else
                    usage
                    error_msg "unknown argument: $1"
                fi
                ;;
            *)
                usage
                error_msg "unknown argument: $1"
                ;;
        esac
    done

    # Normalize args_req to an array for checking
    local req_array=()
    if declare -p args_req 2>/dev/null | grep -q 'declare -a'; then
        req_array=("${args_req[@]}")
    else
        req_array=(${args_req})
    fi

    # Check required arguments automatically if args_req is defined
    check_req_args "${req_array[@]}"
}

# ------------------------------------------------------------------------------
# check required arguments
# ------------------------------------------------------------------------------
check_req_args() {
    local args=(${@})
    local missing_args=()
    for arg in "${args[@]}"; do
        if [[ -z ${!arg} ]]; then
            missing_args+=("--${arg}")
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
    echo -e "date:\t\t$(get_datetime)"
    echo -e "script:\t\t${0}"
    echo -e "user:\t\t${USER}"
    echo -e "host:\t\t${HOSTNAME}"
    echo ""
    for i in ${!args_order[@]}; do
        if [[ -z ${!args_order[$i]} ]]; then
            continue
        fi
        printf "%-10s\t%s\n" "${args_order[$i]}:" "${!args_order[$i]}"
    done
    echo -e "\n--------------------------------------------------------------------------------\n"
    SECONDS=0
}

# ------------------------------------------------------------------------------
# print footer
# ------------------------------------------------------------------------------
print_footer() {
    echo -e "\n--------------------------------------------------------------------------------\n"
    echo -e "date:\t\t$(get_datetime)"
    echo -e "script:\t\t${0}"
    echo -e "user:\t\t${USER}"
    echo -e "host:\t\t${HOSTNAME}"
    echo ""
    for i in ${!args_order[@]}; do
        if [[ -z ${!args_order[$i]} ]]; then
            continue
        fi
        printf "%-10s\t%s\n" "${args_order[$i]}:" "${!args_order[$i]}"
    done
    echo ""
    echo -e "duration:\t`get_duration ${SECONDS}`"
    echo ""
}

# ------------------------------------------------------------------------------
# get args from idx
# ------------------------------------------------------------------------------


get_args_from_idx() {
    local idx=`echo ${1}+1 | bc`
    local root_dir=`get_root_dir kenrod`
    local in_path="${root_dir}/software/scripts/eep170030/ids_long-format_study-all.csv"
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

# ------------------------------------------------------------------------------
# get valid input
# ------------------------------------------------------------------------------
get_valid_input() {
    local usage_str prompt opts default allow_empty input valid=0 missing_args=()

    # usage
    usage_str="\nUsage: $0 -p <prompt> -o <options> [-e <allow_empty>] \
    \n\t-p <prompt>\t\tprompt message (required) \
    \n\t-o <options>\t\tvalid option(s) separated by space (required) \
    \n\t-d <default>\t\tdefault value (optional) \
    \n\t-e <0|1>\t\tallow empty input (0: false [default], 1: true)\n"


    if [ $# -eq 0 ]; then
        echo -e "${usage_str}"
        return 1
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -p)
          prompt=$2
          shift 2
          ;;
        -o)
          opts=()
          shift
          while [[ $# -gt 0 ]] && [[ $1 != -* ]]; do
              opts+=("$1")
              shift
          done
          ;;
        -d)
          default=$2
          shift 2
          ;;
        -e)
          allow_empty=$2
          shift 2
          ;;
        *)
          echo -e "${usage_str}"
          echo "[ERROR] Invalid option: $1"
          return 1
          ;;
      esac
    done

    # Argument validation
    if [[ -z $prompt ]]; then
        missing_args+=("-p <prompt> is required")
    fi
    if [[ -z $opts ]]; then
        missing_args+=("-o <opts> is required")
    fi
    

    if [[ ${#missing_args[@]} -gt 0 ]]; then
        echo "[ERROR] Missing arguments:"
        for msg in "${missing_args[@]}"; do echo "  $msg"; done
        return 1
    fi

    if [[ $allow_empty -ne 0 && $allow_empty -ne 1 ]]; then
        echo "[ERROR] -e allow_empty must be 0 or 1"
        return 1
    fi

    # Prompt loop
    valid=0
    prompt_str="\n[$(get_datetime)] [PROMPT]\t${prompt}\n "
    read -rp "$(printf "${prompt_str}")" input
    while [ $valid -eq 0 ]; do
        if [[ -z "$input" && $allow_empty -eq 0 ]]; then
            prompt_str="\n[$(get_datetime)] [WARNING]\tinvalid input (valid options: ${opts[*]})\n[PROMPT]\t${prompt}\n "
            read -rp "$(printf "${prompt_str}")" input
            continue
        elif [[ -z "$input" && $allow_empty -eq 1 ]]; then
            input=${default:-""}
            valid=1
            break
        fi
        for opt in "${opts[@]}"; do
            if [[ "$input" == "$opt" ]]; then
                valid=1
                break
            fi
        done
        if [[ $valid -eq 0 ]]; then
            prompt_str="\n[$(get_datetime)] [WARNING]\tinvalid input (valid options: ${opts[*]})\n[$(get_datetime)] [PROMPT]\t${prompt}\n "
            read -rp "$(printf "${prompt_str}")" input
        fi
    done

    echo "$input"  # Return the valid input
}

# ------------------------------------------------------------------------------
# module load all
# ------------------------------------------------------------------------------
module_load_all() {
    # usage -----
    usage_module_load_all() {
        echo -e "\n\tusage:\t\tmodule_load_all <module_file>"
        echo -e "\n\toptions:\t\t"
        echo -e "\t\t\t<module_file> - Path to the file containing module names to load, one per line."
        echo -e ""  
    }

    # checks -----
    if [[ $# -ne 1 ]]; then
        usage_module_load_all
        return 0
    fi

    if [[ ! -f $1 ]]; then
        error_msg "module file does not exist ($1)"
    fi

    # main -----
    local module_file=$1
    local modules=()
    local module

    while read -r module; do
        # skip blank lines and comments
        [[ -z "$module" || "$module" =~ ^# ]] && continue
        modules+=("$module")
    done < "$module_file"

    # 2. Check if all modules exist
    for module in "${modules[@]}"; do
        if ! module avail "$module" 2>&1 | grep -q "$module"; then
            error_msg "module not found ($module). run 'module avail' for list of available modules."
        fi
    done

    # 3. Load all modules
    for module in "${modules[@]}"; do
        info_msg "loading module: $module"
        module load "$module"
    done
}
