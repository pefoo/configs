#!/bin/bash

#
# Link dot files. 
#

no_color='false'
while getopts "cb:u:m:" arg; do
  case $arg in
    # Optionally pass the base path for dot files 
    b)
      dotfiles_path="$OPTARG"
      ;;
    u)
      git_user="$OPTARG"
      ;;
    m)
      git_mail="$OPTARG"
      ;;
    c)
      no_color='true'
  esac
done

# Dot files to link

if [ -z "$dotfiles_path" ];then 
  dotfiles_path=$(dirname $(realpath $0))
fi
declare -A dot_files=(
  [$dotfiles_path/bashrc]="$HOME/.bashrc"
  [$dotfiles_path/tmux.conf]="$HOME/.tmux.conf"
  [$dotfiles_path/vimrc]="$HOME/.vimrc"
  [$dotfiles_path/inputrc]="$HOME/.inputrc"
  [$dotfiles_path/gitconfig]="$HOME/.gitconfig"
  [$dotfiles_path/profile]="$HOME/.profile"
)

# Log to console (yellow)
function log_console {
  if $no_color ;then
    echo "$1"
  else 
    echo -e "\e[92m${1}\e[39m"
  fi
}

# print linked dot files 
# Arg1: The created link
# Arg2: The the source file
function log_dot_file {
  if $no_color ;then
    echo "Created symlink: $1 -> $2"
  else
    printf "\e[92mCreated symlinkL %-25s %2s %s\e[39m\n" "${1}" "->" "${2}"
  fi
}


# Create local git user config (contains user name and mail)
function make_gitconfig_local {
  local guser gmail
  if [ ! -z "$git_user" ]; then
    guser="$git_user"
  else 
    echo -en "\e[92mEnter a user name for your git config:\e[39m "
    read guser
  fi
  if [ ! -z "$git_mail" ]; then
    gmail="$git_mail"
  else
    echo -en "\e[92mEnter an email for your git config:\e[39m "
    read gmail
  fi

  local gc_local="$HOME/.gitconfig.local"
  if [ -f "$gc_local" ]; then
    echo 'Local git config already exists. Skipping.'
    return
    #mv "$gc_local" "$gc_local.bak"
  fi

  cat << EOF > "$gc_local"
[user]
  mail = $gmail
  name = $guser
  email = $gmail
EOF
  log_console "Your local git user was created in $gc_local"
  log_console "You may make local changes to your git config using this file"
}

# Update the configs repo and link the registered dot files 
function link_dot_files {
  log_console "Setting up dot files"
  for file in "${!dot_files[@]}";do
    # If the dot file exists and is no symlink, create a backup
    if [ -f "${dot_files[$file]}" -a ! -L "${dot_files[$file]}" ]; then
      log_console "Created a backup of your exsting dot file: ${dot_files[$file]}.bak"
      mv "${dot_files[$file]}" "${dot_files[$file]}.bak"
    fi
    if [ -L "${dot_files[$file]}" ]; then
      # Link already set up
      if [[ "$(readlink -f "${dot_files[$file]}")" == $file ]]; then
        echo "Link for $file already exists. Skipping."
        continue
      fi
      rm "${dot_files[$file]}"
    fi
    log_dot_file ${dot_files[$file]} $file
    ln -s "$file" "${dot_files[$file]}"
  done
}

make_gitconfig_local 
link_dot_files
