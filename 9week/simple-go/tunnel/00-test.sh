# You need to execute commands in root privileges.
# At least you need to have cap_sys_admin, for enter others namespace


# Terminal 1
sudo ip netns add test
sudo ip netns exec test ip link set lo up
go build .
sudo ./tunnel

# Terminal 2
sudo ip netns exec test telnet localhost 3000
# Terminal 3
telnet localhost 3000

# Clean up
sudo ip netns delete test
rm ./tunnel