if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_add_path /opt/homebrew/bin

source (/opt/homebrew/bin/starship init fish --print-full-init | psub)
