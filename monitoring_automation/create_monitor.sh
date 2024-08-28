#!/bin/bash
script_dir="$(dirname $(readlink -f $0))"
monitor_top_dir=$(readlink -f ${script_dir}/..)
ansible-playbook init_monitor.yml -e topdir=${monitor_top_dir} -e monitor_dir=${script_dir}
