name: "{{ getenv "APPNAME" }}-dev"

topology:
  defaults:
    kind: srl
    image: ghcr.io/nokia/srlinux:22.6.1

  nodes:
    srl1:
      binds:
        - "../build:/tmp/build" # mount dir with binaries
        - "../logs/srl1:/var/log/srlinux" # expose srlinux logs to a dev machine
        - "../{{ getenv "APPNAME" }}.yml:/tmp/{{ getenv "APPNAME" }}.yml" # put agent config file to temp dir. It will be copied to appmgr during lab postdeployment
        - "../yang:/opt/{{ getenv "APPNAME" }}/yang" # yang modules
    srl2:
      binds:
        - "../build:/tmp/build" # mount dir with binaries
        - "../logs/srl2:/var/log/srlinux" # expose srlinux logs to a dev machine
        - "../{{ getenv "APPNAME" }}.yml:/tmp/{{ getenv "APPNAME" }}.yml" # put agent config file to temp dir. It will be copied to appmgr during lab postdeployment
        - "../yang:/opt/{{ getenv "APPNAME" }}/yang" # yang modules
  links:
    - endpoints:
        - "srl1:e1-1"
        - "srl2:e1-1"
