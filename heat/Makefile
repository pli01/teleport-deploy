SHELL := /bin/bash
HEAT_TEMPLATE   := heat.yaml
HEAT_PARAM      := param/mycloud.yaml
HEAT_STACK_NAME := seed
HEAT_OPT :=
export 

all: validate create-dry-run create

validate:
	openstack orchestration template validate -t $(HEAT_TEMPLATE) -e $(HEAT_PARAM) $(HEAT_OPT)
create-dry-run:
	openstack stack create --dry-run --wait -t $(HEAT_TEMPLATE) -e $(HEAT_PARAM) -f json $(HEAT_OPT) $(HEAT_STACK_NAME)
create:
	openstack stack create --wait -t $(HEAT_TEMPLATE) -e $(HEAT_PARAM) -f json $(HEAT_OPT) $(HEAT_STACK_NAME)
delete:
	openstack stack delete --wait -y $(HEAT_STACK_NAME) $(HEAT_OPT) || true
