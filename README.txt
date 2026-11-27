This repository contains the configuration changes I have made on my FreeBSD system, as well as my MacOS system.

To apply ./macos to a Mac, run ./sync-macos.sh as your user (-n prints what it would change).

Before wiping the old Mac: run ./wifi-macos.sh export <file> and ./extras-macos.sh export-littlesnitch, and back up ~/.ssh (keys and known_hosts) and your real ~/.gitconfig.work outside this repository.

On a new Mac:
1. Run xcode-select --install, then git clone https://github.com/MegaManSec/dotfiles.git and cd into it.
2. Copy your SSH keys from your backup into ~/.ssh and chmod 600 ~/.ssh/id_*, so ~/install.sh does not generate new ones.
3. On a work Mac only, run mkdir -p ~/.config/dotfiles && touch ~/.config/dotfiles/work, so ./sync-macos.sh also applies ./macos-work (work GitHub organizations and email, work SSH hosts, the work DNS search domain and tailnet, and Tailscale's settings).
4. Give Terminal Full Disk Access (System Settings > Privacy & Security > Full Disk Access), quit and reopen it, then run ./sync-macos.sh, then ~/install.sh, then ./sync-macos.sh again.
5. On a work Mac only, put your work email in ~/.gitconfig.work (seeded with a placeholder); it applies only to repos in the work organizations listed in ~/.gitconfig.local, and every other repo commits as MegaManSec@users.noreply.github.com. Then install Tailscale by hand and sign in.
6. Download and install these apps by hand from their own websites (not with Homebrew): Bitwarden, Claude, Claude Code, Codex, Firefox, Google Chrome, LibreOffice, Little Snitch, Magic Switch and Spotify, plus nvm, Node, yarn and pnpm if you need them (their settings are already synced).
7. Open Little Snitch, approve its network extension, and turn on Settings > Security > Allow access via Terminal.
8. Run ./extras-macos.sh and do the steps it prints at the end.
9. Run ./wifi-macos.sh import <file> with the file exported from the old Mac.
10. Run git remote set-url origin git@github.com:MegaManSec/dotfiles.git to push over SSH.

On a Mac whose built-in keyboard has a § key, create ~/.config/dotfiles/swap-section-key before syncing to swap § and `.

Little Snitch settings (not rules) live in ./littlesnitch-settings.txt, which ./extras-macos.sh applies; refresh it with ./extras-macos.sh export-littlesnitch.

Wi-Fi passwords are private, so they are not stored here: export them with ./wifi-macos.sh export <file> outside this repository (one admin prompt per network with a password), and load that file on the other Mac with ./wifi-macos.sh import <file>.

The following files should be kept in sync:

./macos/Users/jrogers/.nanorc
./freebsd/home/user/.nanorc

./macos/Users/jrogers/.bash_profile
./freebsd/home/user/.bash_profile

./macos/Users/jrogers/.gitconfig
./freebsd/home/user/.gitconfig

./macos/Users/jrogers/.ssh
./freebsd/home/user/.ssh

./macos/usr/local/etc/blocked-hosts
./freebsd/usr/local/etc/blocked-hosts

./macos/usr/local/etc/cloaked-hosts
./freebsd/usr/local/etc/cloaked-hosts

./macos/usr/local/etc/forwarded-hosts
./freebsd/usr/local/etc/forwarded-hosts

./macos/usr/local/etc/nanorc
./freebsd/usr/local/etc/nanorc

./macos/usr/local/bin/multi_block_spam_hostnames
./freebsd/usr/local/bin/multi_block_spam_hostnames

./macos/usr/local/bin/body
./freebsd/usr/local/bin/body

./macos/Users/jrogers/.npmrc
./freebsd/home/user/.npmrc

./macos/Users/jrogers/.yarnrc.yml
./freebsd/home/user/.yarnrc.yml

./macos/Users/jrogers/.yarnrc
./freebsd/home/user/.yarnrc

./macos/Users/jrogers/.config/uv/uv.toml
./freebsd/home/user/.config/uv/uv.toml

./macos/Users/jrogers/Library/Preferences/pnpm/rc
./freebsd/home/user/.config/pnpm/rc

./macos/Users/jrogers/Library/Application Support/Firefox/Profiles/escb03o9.default-release/user.js
./freebsd/home/user/.mozilla/firefox/escb03o9.default-release/user.js

./macos/Users/jrogers/Library/Application Support/Firefox/Profiles/escb03o9.default-release/chrome
./freebsd/home/user/.mozilla/firefox/escb03o9.default-release/chrome

