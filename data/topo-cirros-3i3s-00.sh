source devstack/function-common
PUBLIC_NETID=$( neutron net-external-list | grep -e "\spublic\s" | get_field 1 )

neutron net-create fin-network
neutron subnet-create fin-network 10.168.11.0/24 \
    --name fin-subnet \
    --gateway 10.168.11.1 \
    --dns-nameservers list=true 8.8.8.8 8.8.4.4 \
    --allocation-pool start=10.168.11.2,end=10.168.11.99

neutron net-create service-network
neutron subnet-create service-network 192.168.11.0/24 \
    --name service-subnet \
    --gateway 192.168.11.1 \
    --dns-nameservers list=true 8.8.8.8 8.8.4.4 \
    --allocation-pool start=192.168.11.2,end=192.168.11.99

neutron net-create guest-network
neutron subnet-create guest-network 192.168.33.0/24 \
    --name guest-subnet \
    --gateway 192.168.33.1 \
    --dns-nameservers list=true 8.8.8.8 

neutron router-create expo-router
neutron router-gateway-set expo-router public

neutron router-interface-add expo-router fin-subnet
neutron router-interface-add expo-router service-subnet
neutron router-interface-add expo-router guest-subnet

IMAGE_ID=$(nova image-list | grep cirros-0.3.3 | get_field 1)
FLAVOR_ID=$(nova flavor-list | grep tiny | get_field 1)
USER_DATA=/opt/devtest/interactive-tempest/itempest/data/metadata/itempest-userdata

SV_NETID=$(neutron net-list | grep fin-network | get_field 1)
nova boot fin-acct --image $IMAGE_ID --flavor $FLAVOR_ID \
    --nic net-id=$SV_NETID --user_data $USER_DATA

SV_NETID=$(neutron net-list | grep service-network | get_field 1)
nova boot service-web --image $IMAGE_ID --flavor $FLAVOR_ID \
    --nic net-id=$SV_NETID --user_data $USER_DATA

SV_NETID=$(neutron net-list | grep guest-network | get_field 1)
nova boot guest-web --image $IMAGE_ID --flavor $FLAVOR_ID \
    --nic net-id=$SV_NETID --user_data $USER_DATA

