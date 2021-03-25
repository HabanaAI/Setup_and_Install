#!/bin/bash
#
# Copyright 2021 HabanaLabs, Ltd.
#
# SPDX-License-Identifier: Apache-2.0

HABANA_DRIVER_NAME="habanalabs"
HABANA_PCI_ID="0x1da3"
NICS_NUM=8
EXT_PORTS="1 8 9"

usage()
{
    echo -e "\nusage: $(basename $1) [options]\n"

    echo -e "options:\n"
    echo -e "       --up         toggle up all Habana network interfaces"
    echo -e "       --down       toggle down all Habana network interfaces"
    echo -e "       --status     print status of all Habana network interfaces"
    echo -e "       --set-ip     set IP for all internal Habana network interfaces"
    echo -e "       --unset-ip   unset IP from all internal Habana network interfaces"
    echo -e "  -v,  --verbose    print more logs"
    echo -e "  -h,  --help       print this help"
}

habana_net_list=""
verbose=false
up=0
down=0
status=0
set_ip=0
unset_ip=0
op_sum=0
op=""
num=1

toggle_link()
{
    local net_if=$1
    local op=$2
    local verbose=$3

    sudo ip link set $net_if $op
    if [ $? -ne 0 ]; then
        echo -e "\e[31;1mError, failed to toggle I/F '$net_if'\e[0m"
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
            if_info=`sudo ethtool -i $net_if`
            if [ $? -ne 0 ]; then
                echo "Error, failed to acquire information for the network interface '$net_if'"
                continue
            fi

            driver_name=`echo "$if_info" | grep 'driver' | awk '{print $2}'`
            if [ $driver_name != $HABANA_DRIVER_NAME ]; then
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

if [ $# -gt 2 ]; then
    echo "Error, too many arguments"
    usage $0
    exit 1
fi

while [ -n "$1" ];
do
    case $1 in
    -h  | --help )
        usage $0
        exit 0
        ;;
    --up )
        let up++
        op="up"
        ;;
    --down )
        let down++
        op="down"
        ;;
    --status )
        let status++
        op="status"
        ;;
    --set-ip )
        let set_ip++
        op="set_ip"
        ;;
    --unset-ip )
        let unset_ip++
        op="unset_ip"
        ;;
    -v  | --verbose )
        verbose=true
        ;;
    *)
        echo "Error, bad argument '$1'"
        usage $0
        exit 1
        ;;
    esac
    shift
done

let "op_sum=$up + $down + $status + $set_ip + $unset_ip"
if [ $op_sum -ne 1 ]; then
    echo -e "exactly one operation should be provided"
    usage $0
    exit 1
fi

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

                if_info=`sudo ethtool -i $net_if`
                if [ $? -ne 0 ]; then
                    echo "Error, failed to acquire information for the network interface '$net_if'"
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
                    dev_ifs_up="$dev_ifs_up, $dev_port"
                fi
            else
                let dev_num_down++
                if [ -z "$dev_ifs_down" ]; then
                    dev_ifs_down="$dev_port"
                else
                    dev_ifs_down="$dev_ifs_down, $dev_port"
                fi
            fi
        done

        echo "$dev_name"
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
    for net_if in $habana_net_list; do
        toggle_link $net_if $op $verbose &
    done

    # wait for all the concurrent toggles to complete
    wait

    if [ $verbose = true ]; then
        echo -e ""
    fi

    echo -e "$(wc -w <<< "$habana_net_list") $HABANA_DRIVER_NAME network interfaces were toggled $op"

    # set IPs by default when toggling up
    if [ $up -eq 1 ]; then
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

        if [ $set_ip -eq 1 ]; then
            sudo ifconfig $net_if 192.168.100.$num netmask 255.255.255.0 up

            if [ $? -eq 0 ]; then
                if [ $verbose = true ]; then
                    echo -e "Network I/F '$net_if' got IP 192.168.100.$num"
                fi
                let num++
            else
                echo -e "\e[31;1mNetwork I/F '$net_if' faild to set IP\e[0m"
            fi
        elif [ $unset_ip -eq 1 ]; then
            sudo ifconfig $net_if 0 up

            if [ $? -eq 0 ]; then
                if [ $verbose = true ]; then
                    echo "Network I/F '$net_if' unset its IP"
                fi
            else
                echo -e "\e[31;1mNetwork I/F '$net_if' faild to unset IP\e[0m"
            fi
        fi
    done

    if [ $verbose = true ]; then
        echo -e ""
    fi
fi

exit 0
