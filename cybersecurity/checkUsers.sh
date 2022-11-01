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
if [[ "$response" != "y" ]]; then
    echo "Go create xa & xu"
    exit
fi

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
            sudo userdel $user
            if [[ $? -eq 0 ]]; then
                echo "Deleted $user"
            else
                echo "Failed to delete $user"
            fi
            # echo "$user should be removed"
            # echo "sudo userdel -r $user"
            echo "---"
        else
            sudo userdel $user sudo
            if [[ $? -eq 0 ]]; then
                echo "Removed $user from sudo"
            else
                echo "Failed to remove $user from sudo"
            fi
            # echo "$user should be on others instead of admins"
            # echo "sudo userdel $user sudo"
            echo "---"
        fi
    fi
done <<< "$notme_sudos"

while IFS= read -r user; do
    ok=$(echo "$aothers" | grep "$user" | tail -n1)
    if [[ "$ok" != *"$user"* ]]; then
        okx=$(echo "$aadmins" | grep "$user" | tail -n1)
        if [[ "$okx" != *"$user"* ]]; then
            sudo userdel $user
            if [[ $? -eq 0 ]]; then
                echo "Deleted $user"
            else
                echo "Failed to delete $user"
            fi
            # echo "$user should be removed"
            # echo "sudo userdel -r $user"
            echo "---"
        else
            sudo usermod -aG $user
            if [[ $? -eq 0 ]]; then
                echo "Added $user to sudo"
            else
                echo "Failed to add $user to sudo"
            fi
            # echo "$user should be on admins instead of others"
            # echo "sudo usermod -aG $user"
            echo "---"
        fi
    fi
done <<< "$others"

echo ""
echo "done"
echo ""
exit