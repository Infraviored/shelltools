ssgpt() {
  if [ $# -gt 0 ]; then
    sgpt --shell "$*"
  else
    echo "Paste your content, then press Ctrl-D:"
    sgpt --shell "$(cat)"
  fi
}
