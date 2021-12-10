#################
# Makefile to automate workflows used to instantiate Go-based dev environment
# and perform tasks required throughout the development process

# needs 
# - docker-ce
# - containerlab
#################

APPNAME = demo-app
GOPKGNAME= demo-app

LABFILE = dev.clab.yml
BIN_DIR = $$(pwd)/build
BINARY = $$(pwd)/build/$(APPNAME)

# abs path of a dir that hosts makefile
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# when make is called with `make cleanup=1 some-target` the CLEANUP var will be set to `--cleanup`
# this is used in clab destroy commands to remove the clab-dev lab directory 
CLEANUP=
ifdef cleanup
	CLEANUP := --cleanup
endif

init: venv
	mkdir -p logs/srl1 logs/srl2 build lab $(APPNAME) $(APPNAME)/yang $(APPNAME)/wheels
	
	docker run --rm -e APPNAME=${APPNAME} -v $$(pwd):/tmp hairyhenderson/gomplate:stable --input-dir /tmp/.gen --output-map='/tmp/{{ .in | strings.TrimSuffix ".tpl" }}'
	sudo chown -R $$(id -u):$$(id -g) .
	mv agent.yang ${APPNAME}/yang/${APPNAME}.yang
	mv agent-config.yml ${APPNAME}.yml
	mv dev.clab.yml lab/
	mv main.py run.sh ${APPNAME}/

	sed -i 's/demo-app/${APPNAME}/g' Makefile
	cp .gen/.gitignore .

venv:
	python3 -m venv .venv
	. .venv/bin/activate && \
	pip3 install -U pip wheel && \
	pip3 install -r requirements.txt

# python wheels to install same deps on remote venv
# built with srlinux image to guarantee compatibility with NOS
.PHONY: wheels
wheels:
	docker run --rm -v $$(pwd):/work -w /work --entrypoint 'bash' ghcr.io/nokia/srlinux:latest -c "sudo python3 -m pip install -U pip wheel && sudo pip3 wheel pip wheel -r requirements.txt --no-cache --wheel-dir $(APPNAME)/wheels"

# setting up venv on srl1/srl2 containers
remote-venv: wheels
	cd lab; \
	sudo clab exec -t $(LABFILE) --label clab-node-kind=srl --cmd "bash -c \"sudo python3 -m venv /opt/${APPNAME}/.venv \
&& source /opt/${APPNAME}/.venv/bin/activate && pip3 install --no-cache --no-index /opt/${APPNAME}/wheels/pip* && pip3 install --no-cache --no-index /opt/${APPNAME}/wheels/*\""


destroy-lab:
	cd lab; \
	sudo clab des -t $(LABFILE) $(CLEANUP); \
	sudo rm -f .*.clab.* \
	sudo rm -rf ../logs/*

deploy-lab:
	mkdir -p logs/srl1 logs/srl2
	cd lab; \
	sudo clab dep -t $(LABFILE)

redeploy-lab: destroy-lab deploy-lab create-app-symlink

deploy-all: redeploy-all

redeploy-all: redeploy-lab remote-venv create-app-symlink restart-app

# lint an app and restart app_mgr without redeploying the lab
lint-restart: lint restart-app

show-app-status:
	cd lab; \
	sudo clab exec -t $(LABFILE) --label clab-node-kind=srl --cmd 'sr_cli "show system application $(APPNAME)"'

reload-app_mgr:
	cd lab; \
	sudo clab exec -t $(LABFILE) --label clab-node-kind=srl --cmd 'sr_cli "tools system app-management application app_mgr reload"'

# use rebuild-app when new dependencies are introduced
# and you need to re-create the venv
rebuild-app: venv remote-venv restart-app

restart-app:
	cd lab; \
	sudo clab exec -t $(LABFILE) --label clab-node-kind=srl --cmd 'sr_cli "tools system app-management application $(APPNAME) restart"'

create-app-symlink:
	cd lab; \
	sudo clab exec -t $(LABFILE) --label clab-node-kind=srl --cmd 'sudo ln -s /opt/$(APPNAME)/run.sh /usr/local/bin/$(APPNAME)'

rpm:
	docker run --rm -v $$(pwd):/tmp -w /tmp goreleaser/nfpm package \
	--config /tmp/nfpm.yml \
	--target /tmp/build \
	--packager rpm

clean: destroy-lab remove-files .gitignore

remove-files:
	sudo rm -rf logs build ${APPNAME} lab yang *.yml .venv *.py .gitignore wheels

# create dev .gitignore
.ONESHELL:
.gitignore:
	cat <<- EOF > $@
	/*
	!.gitignore
	!.gen
	!LICENSE
	!Makefile
	!README.md
	!requirements.txt
	!.vscode
	.vscode/*
	!.vscode/tasks.json
	EOF

lint-yang:
	docker run --rm -v $$(pwd):/work ghcr.io/hellt/yanglint yang/*.yang

lint-yaml:
	docker run --rm -v $$(pwd):/data cytopia/yamllint -d relaxed .

lint: lint-yang lint-yaml