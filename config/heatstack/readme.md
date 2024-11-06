# Validate template:

openstack orchestration template validate --template openstack/stack.heat.yaml --environment openstack/stack.env.yaml

# Deploy template:

openstack stack create stack-dev --template openstack/stack.heat.yaml --environment openstack/stack.env.yaml

# Show stack

openstack stack show stack-dev

# Stack output list

openstack stack output list stack-dev

# delete Stack

openstack stack delete stack-dev
