#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env

# configurable timing
: "${KWAIT_TIMEOUT:=600}"   # seconds to wait for resources/conditions
: "${KWAIT_INTERVAL:=5}"    # seconds between polls

build() {
	info "label dpudevices ..."
	kubectl -n dpf-operator-system label dpudevice $DPU1_SERIAL provisioning.dpu.nvidia.com/dpudevice-service-name=border
	kubectl -n dpf-operator-system label dpudevice $DPU2_SERIAL provisioning.dpu.nvidia.com/dpudevice-service-name=mgx
}

delete() {
	info "removing dpudevice service labels .."
	kubectl -n dpf-operator-system label dpudevice $DPU1_SERIAL provisioning.dpu.nvidia.com/dpudevice-service-name-
	kubectl -n dpf-operator-system label dpudevice $DPU2_SERIAL provisioning.dpu.nvidia.com/dpudevice-service-name-
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
