#!/bin/bash

SHOW_INFO=1
SHOW_ERROR=1

## utility functions

# use this function for info output
_info()
{
        [ $SHOW_INFO -eq 1 ] && echo "INFO: ${@}"
}

# use this function for error output ex: _error
_error()
{
        [ $SHOW_ERROR -eq 1 ] && echo "ERROR: ${@}"
}


configure_monorepo_watcher() {
  echo "config/kernel" > family.watch
  echo "config/sources" >> family.watch
  echo "patch/kernel" >> family.watch
  echo "patch/u-boot" >> family.watch
  
  echo "config/boards" > board.watch
  echo "config/bootscripts" >> board.watch

}

translate_family() {
  local family=$1
  local common_family=${family}


  case $family in
  meson-g12b) common_family="meson64"
  ;;
  meson-gxbb) common_family="meson64"
  ;;
  mesgon-gxl) common_family="meson64"
  ;;
  sun4i) common_family="sunxi"
  ;;
  sun5i) common_family="sunxi"
  ;;
  sun6i) common_family="sunxi"
  ;;
  sun7i) common_family="sunxi"
  ;;
  sun8i) common_family="sunxi"
  ;;
  sun9i) common_family="sunxi"
  ;;
  sun50iw1) common_family="sunxi64"
  ;;
  sun50iw2) common_family="sunxi64"
  ;;
  sun50iw6) common_family="sunxi64"
  ;;
  esac
  
  echo "${common_family}"
}

generate_board_table() {  
  config_dir=build/config/boards
  files=$(ls ${config_dir}/*.conf ${config_dir}/*.wip ${config_dir}/*.csc)
  
  rm -f board_table.csv
  
  for file in ${files}; do
    source ${file}
    board=$(basename ${file}|cut -d '.' -f1)
    support_level=$(basename ${file}|cut -d'.' -f2)
    common_family=$(translate_family ${BOARDFAMILY})
    echo "${BOARDFAMILY},${common_family},${BOARD_NAME},${board},${support_level}" >> board_table.csv
done
}

load_board_table() {
#BOARD_TABLE=$(cat ../board_table.csv|sort -r)
readarray BOARD_TABLE < board_table.csv
}

get_files_changed() {
  ## these var values needed by detectGitChanges.sh  
  echo "GIT_COMMIT=${GITHUB_PR_HEAD_SHA}"
  echo "GIT_PREVIOUS_COMMIT=HEAD"
  
  family_changed="$(../monorepo-gitwatcher/detectGitChanges.sh ../family.watch)"
  board_changed="$(../monorepo-gitwatcher/detectGitChanges.sh ../board.watch)"
  
}

get_build_target() {
  local current_score=0
  local board_score=0
  # reverse sort improves grep accuracy
  IFS=$'\n'
  for row in ${BOARD_TABLE[@]}; do
    _info "board row ${row[@]}" 
    family=$(echo $row|cut -d',' -f1)
    board=$(echo $row|cut -d',' -f4)
    for family_row in ${family_changed}; do
      current_score=$(echo $family_row | fgrep -o -e ${family} -e $(translate_family ${family})|wc -c)
      _info "score: ${current_score} | family_row: ${family_row}"
      if [[ $current_score -gt $board_score ]]; then
         board_score=$current_score
         ARMBIAN_BOARD=${board}
         _info "ARMBIAN_BOARD=${board}"
         for branch in current dev legacy; do
           if echo $family_row |fgrep -q $branch; then
              _info "ARMBIAN_BRANCH=${branch}"
              ARMBIAN_BRANCH=${branch}
           fi
         done
        # break 2
      fi
    done
    for board_row in ${board_changed}; do  
      current_score=$(echo $board_row | fgrep -o ${board}|wc -c)
      _info "score: ${current_score} | board_row: ${board_row}"
      board_score=$current_score
      if [[ $current_score -gt $board_score ]]; then
        ARMBIAN_BOARD=${board}
        _info "ARMBIAN_BOARD=${board}"
      fi
    done
  
  done
}

build_kernel() {
  local build_config=${1}
  git checkout ${GIT_COMMIT}
  ./compile.sh ${build_config} BOARD=${ARMBIAN_BOARD} BRANCH=${ARMBIAN_BRANCH}

}

build_image() {
  local build_config=${1}
  ./compile.sh ${build_config} BOARD=${ARMBIAN_BOARD} BRANCH=${ARMBIAN_BRANCH} RELEASE=${ARMBIAN_RELEASE}
}
