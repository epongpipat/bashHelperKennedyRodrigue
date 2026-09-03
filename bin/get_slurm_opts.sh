#!/bin/bash

date_now="$(date +'%Y-%m-%d')"
if command -v get_root_dir >/dev/null 2>&1; then
    root_dir=`get_root_dir kenrod`
elif [[ -x "$(dirname "${BASH_SOURCE[0]}")/get_root_dir" ]]; then
    root_dir=`"$(dirname "${BASH_SOURCE[0]}")/get_root_dir" kenrod`
fi
log_dir="${root_dir}/server/logs/${USER}/${date_now}"
logs_pwd="${log_dir}"

declare -a slurm_opts
slurm_opts+=("-D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=1 --mem=4G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=1 --mem=8G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=3 --mem=16G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=6 --mem=32G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=9 --mem=48G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=12 --mem=64G --partition=kenrod --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=1 --mem=4G --partition=kenrod --nodelist=compute-02 --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=6 --mem=32G --partition=kenrod --nodelist=compute-02 --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")
slurm_opts+=("--nodes=1 --ntasks=1 --cpus-per-task=12 --mem=64G --partition=kenrod --nodelist=compute-02 --output=jid-%A_jname-%x.log --time=1-00:00:00 --export=NONE -D ${log_dir}")

declare -a slurm_desc
slurm_desc+=("log-only")
slurm_desc+=("mem-4G")
slurm_desc+=("mem-8G")
slurm_desc+=("0.25*max")
slurm_desc+=("0.50*max")
slurm_desc+=("0.75*max")
slurm_desc+=("1.00*max")
slurm_desc+=("gpu-min")
slurm_desc+=("0.50*gpu-max")
slurm_desc+=("1.00*gpu-max")

declare -a slurm_opts_desc
slurm_opts_desc=("${slurm_desc[@]}")

# ------------------------------------------------------------------------------
# usage
# ------------------------------------------------------------------------------
usage() {
    echo "Usage: $0 <opt>"
    echo "Options:"
    for i in ${!slurm_opts[@]}; do
        echo -e "\t[${i}] (${slurm_desc[${i}]})\t'${slurm_opts[$i]}' [${i}]"
    done
}

# ------------------------------------------------------------------------------
# parse args
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # if no arguments supplied, show usage
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    if [[ $1 == "-h" || $1 == "--help" ]]; then
        usage
        exit 0
    fi

    if [[ -z ${slurm_opts[$1]} ]]; then
        usage
        echo -e "[ERROR]\tnot a valid option ($1)"
        exit 1
    fi

    if [[ ! -d ${log_dir} ]]; then
        mkdir -p ${log_dir}
    fi
    echo ${slurm_opts[$1]}
fi