_: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    branchNameCheck = config.packages.check-branch-name;
    commitizen = config.packages.commitizen;
  in {
    checks.git-conventions =
      pkgs.runCommand "nixconf-git-conventions" {
        nativeBuildInputs = [
          branchNameCheck
          commitizen
          pkgs.gitMinimal
        ];
      } ''
        for branch in \
          master \
          feat/add-desktop-host \
          flake/update-nixpkgs \
          host/add-t1 \
          module/add-audio \
          renovate/nix-flake-inputs; do
          check-branch-name "$branch"
        done

        for branch in \
          main \
          feature/add-host \
          feat/Add-host \
          feat/add_host \
          feat/add/host \
          feat/add--host \
          release/v1; do
          if check-branch-name "$branch" 2>/dev/null; then
            printf 'Expected invalid branch name to fail: %s\n' "$branch" >&2
            exit 1
          fi
        done

        cz check --allowed-prefixes --message 'feat(host): add fixture'
        cz check --allowed-prefixes --message $'feat(host): add fixture\n\nExplain the reason.\n\nRefs: #1'
        cz check --allowed-prefixes --message 'revert: restore previous kernel'
        for message in \
          'add host' \
          'Merge branch master' \
          'Revert "feat(host): add fixture"' \
          'fixup! feat(host): add fixture' \
          'squash! feat(host): add fixture'; do
          if cz check --allowed-prefixes --message "$message" >/dev/null 2>&1; then
            printf 'Expected invalid commit message to fail: %s\n' "$message" >&2
            exit 1
          fi
        done

        export GIT_AUTHOR_NAME='Git conventions test'
        export GIT_AUTHOR_EMAIL='git-conventions@example.invalid'
        export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
        export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
        git init --quiet repository
        cd repository
        git commit --quiet --allow-empty --message 'chore: initialize fixture'
        git commit --quiet --allow-empty --message 'feat(host): add fixture'
        git commit --quiet --allow-empty --message 'fix(module): update fixture'
        cz check --allowed-prefixes --rev-range HEAD~2..HEAD
        git commit --quiet --allow-empty --message 'temporary snapshot'
        if cz check --allowed-prefixes --rev-range HEAD~1..HEAD >/dev/null 2>&1; then
          printf 'Expected invalid commit range to fail\n' >&2
          exit 1
        fi

        touch "$out"
      '';
  };
}
