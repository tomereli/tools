# Install my environment using ansible-playbook

## Prerequisites - Remote servers

### Remove password prompt for remote user
```
# Edit /etc/sudoers.d/{{ username }}"
# add line: "{{ username }} ALL=(ALL) NOPASSWD: ALL
```

### Add ssh keys

In the host which is used for configuration of other VMs/Hosts, update `~/.ssh/config` to include all hosts, For example:

```
Host centos8-0
	HostName 172.16.16.100
	StrictHostKeyChecking no
	user tester

Host ubuntu20
	HostName 172.16.16.149
	StrictHostKeyChecking no
	user tester

Host ubuntu18
	HostName 172.16.16.124
	StrictHostKeyChecking no
	user tester

Host fedora32
	HostName 172.16.16.188
	StrictHostKeyChecking no
	user tester

```

Finally, run `ssh-copy-id` for each host to set up passwordless ssh authentication.

## Install locally

```
# Clone the repository
git clone https://github.com/tomereli/tools ~/
cd ~/tools/ansible/

# Edit setup.yml to use localhost instead of vms

sudo ansible-playbook -i ansible.cfg setup.yml
```

## Install on the remote server using ansible-playbook

```
# Clone the repository
git clone https://github.com/tomereli/tools ~/
cd ~/tools/ansible/

# Edit ansible.cfg for remote servers
# Edit setup.yml user parameters

ansible-playbook -i ansible.cfg setup.yml
```
