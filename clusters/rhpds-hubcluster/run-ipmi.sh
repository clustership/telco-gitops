ipmitool -I lanplus -H 10.20.144.67 -U admin -P cmb9.admin chassis status

ipmitool -I lanplus -H 10.20.144.67 -U admin -P cmb9.admin raw 0x32 0xca 0x0

# Setup virtual media
ipmitool -I lanplus -H 10.20.144.67 -U admin -P cmb9.admin raw 0x32 0xcb 0x08 0x01
# Check virtual media
ipmitool -I lanplus -H 10.20.144.67 -U admin -P cmb9.admin raw 0x32 0xca 0x08
