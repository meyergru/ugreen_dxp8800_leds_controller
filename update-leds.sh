#! /bin/bash

#set -x

devices=(p n x x x x x x x x)
map=(power netdev disk1 disk2 disk3 disk4 disk5 disk6 disk7 disk8)

gw=$(ip route | awk '/default/ { print $3 }')
if ping -q -c 1 -W 1 $gw >/dev/null; then
        devices[1]=u
fi

# Map sdX to hardware device
declare -A hwmap
while read line
do
        MAP=($line)
        #echo "${MAP[0]} ${MAP[1]}"
        hwmap[${MAP[0]}2]=${MAP[1]:0:1}
done <<< "$(lsblk -S -o NAME,HCTL | tail -n +2)"

# check status of zpool disks
while read line
do
        DEV=($line)
        #echo "${DEV[0]} ${DEV[1]}"

        index=$((${hwmap[${DEV[0]}]} + 2))

        if [ ${DEV[1]} = "ONLINE" ]; then
                #echo "$index on"
                devices[$index]=o
        else
                #echo "$index fail"
                devices[$index]=f
        fi

done <<< "$(zpool status -L | egrep '^\s+sd[a-h][0-9]')"

for i in "${!devices[@]}"; do
        # echo "$i: ${devices[$i]}"
        case "${devices[$i]}" in
                p)
                        ugreen_leds_cli ${map[$i]} -color 255 255 255 -on -brightness 128
                        ;;
                u)
                        ugreen_leds_cli ${map[$i]} -color 255 255 255 -on -brightness 128
                        ;;
                o)
                        ugreen_leds_cli ${map[$i]} -color 0 255 0 -on -brightness 128
                        ;;
                f)
                        ugreen_leds_cli ${map[$i]} -color 255 0 0 -blink 400 600 -brightness 128
                        ;;
                *)
                        ugreen_leds_cli ${map[$i]} -off
                        ;;
        esac
done
