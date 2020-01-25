# ci-testing-tools
scripts, tools, configs for CI-testing

Currently just shell scripts called by jenkins.  May evolve into somethign more elegant such as a jenkins file.

Uses some simple logic for a best-effort attempt to compile a kernel based on what code has changed

## sample jenkins bash script

```
#!/bin/bash

GIT_COMMIT=${GITHUB_PR_HEAD_SHA}
GIT_PREVIOUS_COMMIT=HEAD


source ci-testing-tools/jenkins_ci.sh

configure_monorepo_watcher
generate_test_table
cd build
get_files_changed
get_build_target
build_kernel
```

## dependencies
* https://github.com/slimm609/monorepo-gitwatcher.git
