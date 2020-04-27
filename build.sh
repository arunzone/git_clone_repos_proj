#!/bin/sh -e

REPOSITORIES="nginx/repos"

while getopts u: option
do
  case "${option}"
    in
    u) USER=${OPTARG}
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

prerequisite(){
  if ! command -v jq > /dev/null; then
    echo "jq is used to parse json from git api, installation begins please wait..." && \
    brew install jq && \
    echo "jq is succesfully installed"
  fi
}

clone_repos(){
  mkdir $REPOSITORIES
  pushd $REPOSITORIES
  curl -s -k --user $USER "https://git.hq.local/rest/api/1.0/projects/WEBART/repos?limit=999" > repos.json && \
  cat repos.json | jq '.values | .[] | .links.clone  | .[] | select(.name | contains("ssh")) | .href' | sed 's/.\{1\}$//' | sed 's/^.\{1\}//' | xargs -n1 | xargs -I{} git clone {} && \
  echo "All artifact repositories cloned"
  popd
}

update_repos(){
  pushd $REPOSITORIES
  echo "update existing artifacts"
  for path in *; do
    [ -d "${path}" ] || continue # if not a directory, skip
    cd $path && \
      echo "updating ${path} ..." && \
      git pull && \
    cd .. && \
    sleep 2
  done

}

setup_repos(){
  if [ ! -d "$REPOSITORIES" ]; then
    clone_repos
  else
    update_repos
  fi
}

cleanup(){
  echo "cleanup"
}

trap cleanup EXIT

prerequisite
setup_repos
