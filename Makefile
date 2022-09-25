.ONESHELL:

define to-file
	printf '%b\n' "$$(cat $1)" > $2
endef

define git-clone
	[ -d $2/.git ] || git clone $1 $2
	(cd $2; git pull $1)
endef

all: \
	brew \
	~/.gitconfig \
	.targets/rc-files \
	~/.emacs.d \
	| targets

~/.gitconfig: git/config
	$(call to-file,git/config,$@)

~/.emacs.d: | ~/.doom.d
	git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install

.targets/rc-files: rc.org | ~/.doom.d ~/bin
	emacs --batch -l org --eval "(org-babel-tangle-file \"$<\")"
	touch $@

# rclone
~/.config/rclone:
	mkdir -p $@

# TODO op install requirement
~/.config/rclone/rclone.conf: ~/.config/rclone
	op get document olst7uwyzbg4lbb6567u67765i --output ~/.config/rclone/rclone.conf

# this is not working, need to init the local repo with a new name first
# Annexes 
# define setup-annex
# 	$(call git-clone,git@gitlab.com:d.costaras/annex-$(if $2,$2,$1).git,~/$1)
# 	cd ~/$1 && git annex enableremote drive
# endef

# ~/comics:
# 	$(call setup-annex,comics)

# ~/books:
# 	$(call setup-annex,books)

# ~/Music:
# 	cd $@ && rm .DS_Store .localized
# 	$(call setup-annex,Music,music)

# ~/Movies:
# 	cd $@ && rm .DS_Store .localized
# 	$(call setup-annex,Music,music)

# Git annex
~/bin/git-annex-remote-rclone: 
	$(call git-clone,git@github.com:dcostaras/git-annex-remote-rclone.git,/tmp/git-annex-remote)
	cp /tmp/git-annex-remote/git-annex-remote-rclone $@

# TODO: install brew rule
# TODO export ssh keys from 1password: github-key
# TODO touchid sudo
# TODO rclone and general config out of 1password

.targets/ql-stephen: | .targets/brew
	xattr -cr ~/Library/QuickLook/QLStephen.qlgenerator
	qlmanage -r
	qlmanage -r cache
	touch $@

.targets/rc-init: rcs/rc.init.org
	emacs --batch -l org --eval "(org-babel-tangle-file \"$<\")"
	touch $@

.targets/hosts-install: | .targets/brew ~/src/hosts
	$(call git-clone,https://github.com/StevenBlack/hosts.git,~/src/hosts)
	pip3 install requests lxml bs4
	touch $@

hosts: | .targets/brew .targets/hosts-install
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social

.targets/cellar-cask:
	echo 'export PATH="/usr/local/opt/texinfo/bin:$PATH"' >> ~/.bash_profile

.targets/install-brew: | .targets
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> /Users/donavan/.zprofile
	eval "$$(/opt/homebrew/bin/brew shellenv)"
	touch $@

brew: .targets/brew
.targets/brew: Brewfile 
	-brew bundle --file $<
	touch $@

.targets/wireguard: | .targets/brew-commands
	mkdir -p ~/.config/wireguard
	cd ~/.config/wireguard && wg genkey | tee privatekey | wg pubkey > publickey
	cd ~/.config/wireguard && sudo chmod -R og-rwx ~/.config/wireguard/*
	touch $@

.targets:
	mkdir -p $@

targets: ~/src ~/bin
	mkdir -p $@

~/bin:
	mkdir -p $@

~/src:
	mkdir -p $@

~/.doom.d:
	mkdir -p $@

~/src/hosts:
	mkdir -p $@
