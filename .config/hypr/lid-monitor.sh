#!/usr/bin/env bash

set -euo pipefail

internal_monitor="eDP-1"
internal_mode="highrr,0x0,1"
lock_file="/tmp/hypr-lid-monitor.lock"

lid_state() {
    local state_file

    for state_file in /proc/acpi/button/lid/*/state; do
        if [[ -f "$state_file" ]] && grep -qi "closed" "$state_file"; then
            echo "closed"
            return 0
        fi
    done

    echo "open"
}

external_monitor_count() {
    local count=0
    local name=""

    while IFS= read -r line; do
        if [[ $line =~ ^Monitor[[:space:]]+([^[:space:]]+) ]]; then
            name="${BASH_REMATCH[1]}"
            if [[ $name != "$internal_monitor" ]]; then
                ((count++))
            fi
        fi
    done < <(hyprctl monitors 2>/dev/null || true)

    echo "$count"
}

on_battery() {
    local status_file

    for status_file in /sys/class/power_supply/BAT*/status; do
        if [[ -f "$status_file" ]] && grep -qi "^Discharging$" "$status_file"; then
            return 0
        fi
    done

    return 1
}

enable_internal() {
    hyprctl keyword monitor "${internal_monitor},${internal_mode}" >/dev/null
}

disable_internal() {
    hyprctl keyword monitor "${internal_monitor},disable" >/dev/null
}

desired_state() {
    if [[ "$(lid_state)" == "closed" && "$(external_monitor_count)" -gt 0 ]]; then
        echo "disabled"
    else
        echo "enabled"
    fi
}

apply_state() {
    case "$1" in
        enabled)
            enable_internal
            ;;
        disabled)
            disable_internal
            ;;
        *)
            echo "unknown state: $1" >&2
            exit 1
            ;;
    esac
}

watch_changes() {
    local last_state=""
    local next_state=""
    local last_external_count=""
    local next_external_count=""

    exec 9>"$lock_file"
    flock -n 9 || exit 0

    last_external_count="$(external_monitor_count)"

    while true; do
        next_external_count="$(external_monitor_count)"
        next_state="$(desired_state)"

        if [[ "$next_state" != "$last_state" ]]; then
            apply_state "$next_state"
            last_state="$next_state"
        fi

        if [[ "$last_external_count" -gt 0 && "$next_external_count" -eq 0 ]] && on_battery; then
            systemctl suspend
        fi

        last_external_count="$next_external_count"
        sleep 2
    done
}

action="${1:-sync}"

case "$action" in
    open)
        enable_internal
        ;;
    close)
        if [[ "$(external_monitor_count)" -gt 0 ]]; then
            disable_internal
        else
            enable_internal
        fi
        ;;
    sync)
        apply_state "$(desired_state)"
        ;;
    watch)
        watch_changes
        ;;
    *)
        echo "usage: $0 [open|close|sync|watch]" >&2
        exit 1
        ;;
esac
