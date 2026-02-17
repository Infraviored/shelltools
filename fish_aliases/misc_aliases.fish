function srcvenv -d "Activate local virtual environment"
    if test -d venv
        source venv/bin/activate.fish
    else if test -d .venv
        source .venv/bin/activate.fish
    else
        echo "No venv or .venv found."
    end
end

alias robotlaptopssh="ssh florian@10.0.1.51"
