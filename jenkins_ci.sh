#!/bin/bash

configure_monorepo_watcher() {
  echo "config/kernel" > family.watch
  echo "config/sources" >> family.watch
  echo "patch/kernel" >> family.watch
  echo "patch/u-boot" >> family.watch
  
  echo "config/boards" > board.watch
  echo "config/bootscripts" >> board.watch

}

generate_test_table() {  
  config_dir=build/config/boards
  files=$(ls ${config_dir}/*.conf ${config_dir}/*.wip ${config_dir}/*.csc)
  
  rm -f test_table.csv
  
  for file in ${files}; do
    source ${file}
    board=$(basename ${file}|cut -d '.' -f1)
    support_level=$(basename ${file}|cut -d'.' -f2)
    echo "${BOARDFAMILY},${BOARD_NAME},${board},${support_level}" >> test_table.csv

done

}

get_files_changed() {
  ## these var values needed by detectGitChanges.sh  
 # GIT_COMMIT=${GITHUB_PR_HEAD_SHA}
 # GIT_PREVIOUS_COMMIT=HEAD
  
  family_changed="$(../monorepo-gitwatcher/detectGitChanges.sh ../family.watch)"
  board_changed="$(../monorepo-gitwatcher/detectGitChanges.sh ../board.watch)"
  
}

get_build_target() {
  OLDIFS=${IFS}
  IFS=$'\n'
  
  # reverse sort improves grep accuracy
  for row in $(cat ../test_table.csv|sort -r); do
    
    family=$(echo $row|cut -d',' -f1)
    board=$(echo $row|cut -d',' -f3)
    for family_row in ${family_changed}; do
      echo "family_row: ${family_row}"
      if echo $family_row | fgrep -q $family; then
         ARMBIAN_BOARD=${board}
         for branch in current dev legacy; do
           if echo $family_row |fgrep -q $branch; then
              echo "ARMBIAN_BRANCH=${branch}"
              ARMBIAN_BRANCH=${branch}
           fi
         done
         break 2
      fi
    done
    for board_row in ${board_changed}; do  
      if echo $board_row | fgrep -q $board; then
        ARMBIAN_BOARD=${board}
        break
      fi
    done
  
  done
  IFS=${OLDIFS}
}

build_kernel() {
  local build_config=$1
  git checkout ${GIT_COMMIT}
  ./compile.sh CONFIG=${build_config} BOARD=${ARMBIAN_BOARD} BRANCH=${ARMBIAN_BRANCH}

}

