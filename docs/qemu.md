# QEMU


## Networking
- vmnet-bridge
- vmnet-host
- vmnet-shared
```xml
<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="">
...
  <qemu:commandline>
    <qemu:arg value="-netdev"/>
    <qemu:arg value="vmnet-shared,id=hostnet0"/>
    <qemu:arg value="-device"/>
    <qemu:arg value="virtio-net-pci,id=net0,netdev=hostnet0,addr=0x3"/>
  </qemu:commandline>
</domain>
```