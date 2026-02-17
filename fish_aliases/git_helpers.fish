function gitupdatelast-add-amend-forcewithlease
    if git rev-parse --git-dir >/dev/null 2>&1
        git add . && git commit --amend --no-edit && git push --force-with-lease
    else
        echo "Not in a git repository"
    end
end
