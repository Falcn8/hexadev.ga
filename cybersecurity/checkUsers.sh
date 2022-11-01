#/bin/bash

# Get the users
everyone=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)
sudos=$(grep -Po '^sudo.+:\K.*$' /etc/group)
sudos=$(tr -s ',' ' ' <<< "$sudos")
notme_sudos=$(awk 'NF' <<< "$(tr ' ' '\n' <<< "${sudos//$USER/}")")
temp=$everyone
others=''

while IFS= read -r user; do
    if [[ $sudos != *"$user"* ]]; then
        others+="$user "
    fi
done <<< "$temp"

others=${others::-1}
others=$(tr -s ' ' '\n' <<< "$others")

echo "Admins: "$sudos
echo "Others: "$others
echo ""

# Fix the authorized users

echo -n "Have you created xa & xu? (y/n): "
read response
echo "Read response: $response"
if [[ "$response" != "y" ]]; then
    echo "Go create xa & xu"
    exit
fi
echo "Finished if statement"

# echo -n "File for Authorized Administrators: "
# read filename
# aadmins=$(cat $filename) || exit
aadmins=$(cat xa) || exit

# echo -n "File for Authorized Users: "
# read filename
# aothers=$(cat $filename) || exit
aothers=$(cat xu) || exit

echo ""
echo "---"

while IFS= read -r user; do
    ok=$(echo "$aadmins" | grep "$user" | tail -n1)
    if [[ "$ok" != *"$user"* ]]; then
        okx=$(echo "$aothers" | grep "$user" | tail -n1)
        if [[ "$okx" != *"$user"* ]]; then
            # echo "$user should be removed"
            echo "sudo userdel -r $user"
            echo "---"
            sudo userdel -r $user
        else
            # echo "$user should be on others instead of admins"
            echo "sudo userdel $user sudo"
            echo "---"
            sudo userdel $user sudo
        fi
    fi
done <<< "$notme_sudos"

while IFS= read -r user; do
    ok=$(echo "$aothers" | grep "$user" | tail -n1)
    if [[ "$ok" != *"$user"* ]]; then
        okx=$(echo "$aadmins" | grep "$user" | tail -n1)
        if [[ "$okx" != *"$user"* ]]; then
            # echo "$user should be removed"
            echo "sudo userdel -r $user"
            echo "---"
            sudo userdel -r $user
        else
            # echo "$user should be on admins instead of others"
            echo "sudo usermod -aG $user"
            echo "---"
            sudo usermod -aG $user
        fi
    fi
done <<< "$others"

echo ""
echo "done"
echo ""
exit