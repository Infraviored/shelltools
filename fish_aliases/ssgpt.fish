function ssgpt
    if count $argv > 0
        sgpt --shell "$argv"
    else
        echo "Paste your content, then press Ctrl-D:"
        sgpt --shell (cat)
    end
end
