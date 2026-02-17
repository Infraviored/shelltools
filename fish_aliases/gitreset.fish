function gitreset
    if git rev-parse --git-dir >/dev/null 2>&1
        git reset --hard origin/(git symbolic-ref --short HEAD)
    else
        echo "Not in a git repository"
    end
end
