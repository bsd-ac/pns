#!/bin/bash

die() { echo "$*" 1>&2 ; exit 1; }

if [ $# -lt 2 ]; then
	die "usage: $0 [pod/container name] [command]"
fi
	
_name="$1"
shift

_container_name=""
if podman pod exists "$_name" > /dev/null 2>&1 ; then
	_container_name="$(podman pod inspect "${_name}" | jq -r '.InfraContainerID')"
	if [ "${_container_name}" = "null" ] || [ -z "${_container_name}" ]; then
		die "Could not get infra container for '${_name}'"
	fi
elif podman container exists "$_name" > /dev/null 2>&1 ; then
	_container_name="$_name"
else
	die "No pod or container by the name of '$_name'"
fi

if [ "$(podman container inspect -f '{{.State.Status}}' "${_container_name}")" != "running" ]; then
        die "Container '$_container_name' is not running"
fi

_cpid="$(podman container inspect -f '{{.State.Pid}}' "${_container_name}")"

exec nsenter --preserve-credentials --user --cgroup --ipc --uts --net --pid --target ${_cpid} "$@"
