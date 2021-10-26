#!/bin/bash
#
# Copyright (C) 2020 HabanaLabs, Ltd.
# All Rights Reserved.
#
# Unauthorized copying of this file, via any medium is strictly prohibited.
# Proprietary and confidential.
#

readonly HABANA_DRIVER_NAME="habanalabs"
readonly HABANA_PCI_ID="0x1da3"
readonly NICS_NUM=8
readonly IP_PREFIX="192.168.100."
EXT_PORTS="1 8 9"

usage()
{
    echo -e "\nusage: $(basename $1) [options]\n"

    echo -e "options:\n"
    echo -e "       --up         toggle up all interfaces"
    echo -e "       --down       toggle down all interfaces"
    echo -e "       --status     print status of all interfaces"
    echo -e "       --set-ip     set IP for all internal interfaces"
    echo -e "       --unset-ip   unset IP from all internal interfaces"
    echo -e "       --set-pfc    set PFC (enabled=0,1,2,3)"
    echo -e "       --unset-pfc  unset PFC (enabled=none)"
    echo -e "       --check-pfc  dump PFC configuration"
    echo -e "       --gaudi2     chip-type is Gaudi 2"
    echo -e "       --no-ip      don't change IPs on toggle up (can be used with --up only)"
    echo -e "  -v,  --verbose    print more logs"
    echo -e "  -h,  --help       print this help"
}

habana_net_list=""
ip_addrs=""
ip_addr=""
verbose=false
up=0
down=0
status=0
set_ip=0
unset_ip=0
set_pfc=0
unset_pfc=0
check_pfc=0
no_ip=0
op=""
num=1
my_sudo=""
if [ $EUID -ne 0 ]; then
    my_sudo="sudo"
fi

toggle_link()
{
    local net_if=$1
    local op=$2
    local verbose=$3

    $my_sudo ip link set $net_if $op
    if [ $? -ne 0 ]; then
        echo "Failed to toggle I/F '$net_if'"
        exit 1
    fi

    if [ $verbose = true ]; then
        echo "Network I/F '$net_if' was toggled $op"
    fi
}

build_net_ifs_global_list()
{
    local net_if
    local if_info
    local driver_name

    for net_if in /sys/class/net/*/ ; do
        net_if=$(basename $net_if)

        # ignore loopback and virtual ethernet devices
        if [ $net_if == "lo" ] || [ `echo $net_if | cut -c1-4` == "veth" ]; then
            continue
        fi

        # consider habanalabs NICs only
        if [ -d /sys/class/net/$net_if/device/ ]; then
            if [ $(cat /sys/class/net/$net_if/device/vendor) != $HABANA_PCI_ID ]; then
                continue
            fi
        else
            # ignore characters including and after '@' in interface name
            net_if=`echo "$net_if" | cut -d'@' -f1`

            # ignore NICs which aren't managed by KMD
            if_info=`$my_sudo ethtool -i $net_if`
            if [ $? -ne 0 ]; then
                echo "Failed to acquire information for the network interface '$net_if'"
                continue
            fi

            driver_name=`echo "$if_info" | grep 'driver' | awk '{print $2}'`
            if [[ $driver_name != $HABANA_DRIVER_NAME* ]]; then
                continue
            fi
        fi

        habana_net_list="$habana_net_list $net_if"
    done

    if [ -z "$habana_net_list" ]; then
        echo "Warning: no $HABANA_DRIVER_NAME network interfaces were detected"
        exit 1
    fi
}

check_flags ()
{
    local sum

    if [ $status -gt 1 ] || [ $up -gt 1 ] || [ $down -gt 1 ] || [ $set_ip -gt 1 ] || [ $unset_ip -gt 1 ] || [ $set_pfc -gt 1 ] || [ $unset_pfc -gt 1 ] || [ $check_pfc -gt 1 ] || [ $no_ip -gt 1 ]; then
        echo "each flag should be used once"
        usage $0
        exit 1
    fi

    let "sum=$up + $down + $set_ip + $unset_ip + $set_pfc + $unset_pfc + $check_pfc + $no_ip"
    if [ $status -ne 0 ] && [ $sum -ne 0 ]; then
        echo "status flag can't be combined with other flags"
        usage $0
        exit 1
    fi

    let "sum=$up + $down"
    if [ $sum -gt 1 ]; then
        echo "up and down flags can't be combined together"
        usage $0
        exit 1
    fi

    let "sum=$set_ip + $unset_ip + $set_pfc + $unset_pfc + $check_pfc + $no_ip"
    if [ $down -ne 0 ] && [ $sum -ne 0 ]; then
        echo "down flag can't be combined with other flags"
        usage $0
        exit 1
    fi

    let "sum=$set_ip + $unset_ip + $set_pfc + $unset_pfc + $check_pfc"
    if [ $up -ne 0 ] && [ $sum -ne 0 ]; then
        echo "up flag can be combined only with no-ip flag"
        usage $0
        exit 1
    fi

    let "sum=$set_ip + $unset_ip"
    if [ $sum -gt 1 ]; then
        echo "set-ip and unset-ip flags can't be combined together"
        usage $0
        exit 1
    fi

    let "sum=$set_pfc + $unset_pfc + $check_pfc"
    if [ $sum -gt 1 ]; then
        echo "PFC flags can't be combined together"
        usage $0
        exit 1
    fi
}

show_prog_bar ()
{
    local progress
    local done
    local left

    let progress=(${1}*100/${2}*100)/100
    let done=(${progress}*4)/10
    let left=40-$done

    done=$(printf "%${done}s")
    left=$(printf "%${left}s")

    printf "\r$3 : [${done// /\#}${left// /-}] ${progress}%%"
}

sleep_with_prog_bar ()
{
    local end
    local i

    let end=($(wc -w <<< "$habana_net_list")/2)+10

    for i in $(seq 1 ${end})
    do
        sleep 0.1
        show_prog_bar ${i} ${end} $1
    done

    echo ""
}

while [ -n "$1" ];
do
    case $1 in
    -h  | --help )
        usage $0
        exit 0
        ;;
    --up )
        let up++
        ;;
    --down )
        let down++
        ;;
    --status )
        let status++
        ;;
    --set-ip )
        let set_ip++
        ;;
    --unset-ip )
        let unset_ip++
        ;;
    --set-pfc )
        let set_pfc++
        ;;
    --unset-pfc )
        let unset_pfc++
        ;;
    --check-pfc )
        let check_pfc++
        ;;
    --gaudi2 )
        EXT_PORTS=""
        ;;
    --no-ip )
        let no_ip++
        ;;
    -v  | --verbose )
        verbose=true
        ;;
    *)
        echo "bad argument '$1'"
        usage $0
        exit 1
        ;;
    esac
    shift
done

check_flags

if [ $status -eq 1 ]; then
    for (( i=0; i<$NICS_NUM; i++ )); do
        dev_name="hl$i"
        if [ ! -d /sys/class/habanalabs/$dev_name/ ]; then
            echo "$dev_name doesn't exist"
            continue
        fi

        if [ "$(cat /sys/class/habanalabs/$dev_name/status)" != "Operational" ]; then
            echo "$dev_name is not operational"
            continue
        fi

        pci_addr=$(cat /sys/class/habanalabs/$dev_name/pci_addr)
        dev_ifs=""
        dev_ifs_up=""
        dev_ifs_down=""
        dev_num_up=0
        dev_num_down=0

        if [ -d /sys/bus/pci/devices/$pci_addr/net/ ]; then
            for dev_if in /sys/bus/pci/devices/$pci_addr/net/*/; do
                dev_ifs="$dev_ifs $dev_if"
            done
        else
            for net_if in /sys/class/net/*/; do
                net_if=$(basename $net_if)

                # ignore loopback and virtual ethernet devices
                if [ $net_if == "lo" ] || [ `echo $net_if | cut -c1-4` == "veth" ]; then
                    continue
                fi

                # ignore characters including and after '@' in interface name
                net_if=`echo "$net_if" | cut -d'@' -f1`

                if_info=`$my_sudo ethtool -i $net_if`
                if [ $? -ne 0 ]; then
                    echo "Failed to acquire information for the network interface '$net_if'"
                    exit 1
                fi

                # ignore interfaces of other devices
                bus_info=`echo "$if_info" | grep 'bus-info' | awk '{print $2}'`
                if [ $bus_info != $pci_addr ]; then
                    continue
                fi

                dev_ifs="$dev_ifs $net_if"
            done
        fi

        for dev_if in $dev_ifs; do
            dev_if=$(basename $dev_if)

            if [ ! -f /sys/class/net/$dev_if/dev_port ] ||
                   [ ! -f /sys/class/net/$dev_if/operstate ]; then
                echo "can't get dev_port/opersate of $dev_if"
                exit 1
            fi

            dev_port=$(cat /sys/class/net/$dev_if/dev_port)

            if [ $(cat /sys/class/net/$dev_if/operstate) == "up" ]; then
                let dev_num_up++
                if [ -z "$dev_ifs_up" ]; then
                    dev_ifs_up="$dev_port"
                else
                    dev_ifs_up="$dev_ifs_up $dev_port"
                fi
            else
                let dev_num_down++
                if [ -z "$dev_ifs_down" ]; then
                    dev_ifs_down="$dev_port"
                else
                    dev_ifs_down="$dev_ifs_down $dev_port"
                fi
            fi
        done

        echo "$dev_name"

        if [ -z "$dev_ifs_up" ] && [ -z "$dev_ifs_down" ]; then
            echo "no interfaces were detected"
            continue
        fi

        # sort lists in ascending order
        dev_ifs_up=$(echo $dev_ifs_up | xargs -n1 | sort -n | xargs)
        dev_ifs_down=$(echo $dev_ifs_down | xargs -n1 | sort -n | xargs)
        # add commas
        dev_ifs_up=${dev_ifs_up//" "/", "}
        dev_ifs_down=${dev_ifs_down//" "/", "}

        if [ $dev_num_up -gt 0 ]; then
            echo "$dev_num_up ports up ($dev_ifs_up)"
        fi
        if [ $dev_num_down -gt 0 ]; then
            echo "$dev_num_down ports down ($dev_ifs_down)"
        fi
    done
else
    build_net_ifs_global_list
fi

if [ $up -eq 1 ] || [ $down -eq 1 ]; then
    if [ $up -eq 1 ]; then
        op="up"
    else
        op="down"
    fi

    sleep_with_prog_bar $op &

    for net_if in $habana_net_list; do
        toggle_link $net_if $op $verbose &
    done

    # wait for all the concurrent toggles to complete
    wait

    if [ $verbose = true ]; then
        echo -e ""
    fi

    echo -e "$(wc -w <<< "$habana_net_list") $HABANA_DRIVER_NAME network interfaces were toggled $op"

    # set IPs by default when toggling up unless explicitly asked not to
    if [ $up -eq 1 ] && [ $no_ip -eq 0 ]; then
        let set_ip++
        if [ $verbose = true ]; then
            echo -e "Setting IP for all internal interfaces"
            echo -e "(run this script with '--unset-ip' to unset)"
        fi
    fi
fi

if [ $set_ip -eq 1 ] || [ $unset_ip -eq 1 ]; then
    for net_if in $habana_net_list; do
        # skip non-external ports
        dev_port=$(cat /sys/class/net/$net_if/dev_port)
        echo $EXT_PORTS | grep -w -q $dev_port
        if [ $? -eq 0 ]; then
            continue
        fi

        ip_addrs=$(ip addr show $net_if | grep "inet\b" | awk '{print $2}' | grep $IP_PREFIX)

        if [ $set_ip -eq 1 ]; then
            if [ -n "$ip_addrs" ]; then
                continue
            fi

            ip_addr=($IP_PREFIX$num/24)
            $my_sudo ip addr add $ip_addr dev $net_if

            if [ $? -eq 0 ]; then
                if [ $verbose = true ]; then
                    echo -e "Network I/F '$net_if' set IP $ip_addr"
                fi
                let num++
            else
                echo "Network I/F '$net_if' failed to set IP $ip_addr"
            fi
        elif [ $unset_ip -eq 1 ]; then
            for ip_addr in $ip_addrs; do
                $my_sudo ip addr del $ip_addr dev $net_if

                if [ $? -eq 0 ]; then
                    if [ $verbose = true ]; then
                        echo "Network I/F '$net_if' unset IP $ip_addr"
                    fi
                else
                    echo "Network I/F '$net_if' failed to unset IP $ip_addr"
                fi
            done
        fi
    done

    if [ $verbose = true ]; then
        echo -e ""
    fi
fi

if [ $set_pfc -eq 1 ] || [ $unset_pfc -eq 1 ] || [ $check_pfc -eq 1 ]; then
    which lldptool > /dev/null
    if [ $? -ne 0 ]; then
        echo "lldptool is not installed"
        exit 1
    fi

    if [ $set_pfc -eq 1 ]; then
        op="set_pfc"
    elif [ $unset_pfc -eq 1 ]; then
        op="unset_pfc"
    else
        op="check_pfc"
    fi

    for net_if in $habana_net_list; do
        if [ $check_pfc -eq 1 ] || [ $verbose = true ]; then
            echo -e "$op '$net_if'"
        fi
        if [ $set_pfc -eq 1 ]; then
            $my_sudo lldptool -T -i $net_if -V PFC enabled=0,1,2,3 > /dev/null
        elif [ $unset_pfc -eq 1 ]; then
            $my_sudo lldptool -T -i $net_if -V PFC enabled=none > /dev/null
        else
            $my_sudo lldptool -t -i $net_if -V PFC -c enabled
        fi

        if [ $? -ne 0 ]; then
            echo "Error, $op '$net_if'"
            exit 1
        fi
    done

    if [ $verbose = true ]; then
        echo -e ""
    fi
fi

exit 0
