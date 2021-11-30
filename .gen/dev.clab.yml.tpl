name: "{{ndkappname}}-dev"

topology:
  defaults:
    kind: srl
    image: ghcr.io/nokia/srlinux:21.6.4

  nodes:
    srl1:
      binds:
        - "../build:/tmp/build" # mount dir with binaries
        - "../logs/srl1:/var/log/srlinux" # expose srlinux logs to a dev machine
        - "../{{ndkappname}}.yml:/etc/opt/srlinux/appmgr/{{ndkappname}}.yml" # put agent config file to appmgr directory
        - "../yang:/opt/{{ndkappname}}/yang" # yang modules
    srl2:

  links:
    - endpoints:
        - "srl1:e1-1"
        - "srl2:e1-1"
