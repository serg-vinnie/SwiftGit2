#include "git2.h"

__attribute__((constructor))
static void SwiftGit2Init(void) {
    git_libgit2_init();
}
