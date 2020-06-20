# ci-testing-tools
scripts, tools, configs for CI-testing

Currently just shell functions included by ~jenkins~ github actions.  

Uses some simple scoring logic for a best-effort attempt to compile a kernel based on what code has changed

## sample github actions bash script

```
#!/bin/bash

         cd build
         GIT_COMMIT=$(echo $GITHUB_SHA)
         GIT_PREVIOUS_COMMIT=$(git rev-parse origin/$GITHUB_BASE_REF)
         ARMBIAN_BOARD=tritium-h5
         ARMBIAN_BRANCH=current
         cd ..
         env
         source ci-testing-tools/jenkins_ci.sh
         
         mkdir -p build/userpatches
         cp -f ci-testing-tools/config-jenkins-kernel.conf build/userpatches/
         configure_monorepo_watcher
         generate_board_table
         load_board_table
         cd build
         get_files_changed
         get_build_target
         git checkout ${GITHUB_SHA}
         git branch -v
         export GPG_TTY=$(tty)
         build_kernel jenkins-kernel
```

## dependencies

* this repo
* armbian/build

## jenkins plugins
* https://plugins.jenkins.io/github-pullrequest
* https://plugins.jenkins.io/multiple-scms
* https://plugins.jenkins.io/pipeline-githubnotify-step
* https://plugins.jenkins.io/pipeline-github


## notes
### get matches from old builds
```
for log in */builds/*/log;do fgrep family_row $log|fgrep changed;done|uniq|awk  '{print $2}'
```
