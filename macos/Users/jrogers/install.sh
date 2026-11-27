#!/bin/sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --file="$HOME/Brewfile"
[ -x /opt/homebrew/bin/bash ] && sudo chsh -s /opt/homebrew/bin/bash jrogers

sudo brew services start dnscrypt-proxy
sudo /usr/local/bin/multi_block_spam_hostnames

for key in personal-random personal-github work-github; do
  if [ ! -f ~/.ssh/id_ed25519-$key ]; then
    echo "Generating $key SSH key"
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-$key
  fi
done
