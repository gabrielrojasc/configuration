
# ASCII BOAT SHELL INTEGRATION START boat
case ":$PATH:" in
  *":/Users/gabriel/.ascii/bin:"*) ;;
  *) PATH="/Users/gabriel/.ascii/bin:$PATH" ;;
esac
export PATH
# ASCII BOAT SHELL INTEGRATION END boat

export PLAYWRIGHT_MCP_EXECUTABLE_PATH=/Applications/Helium.app/Contents/MacOS/Helium
export PLAYWRIGHT_MCP_PROFILE_DIR_NAME="Profile 1"
export PLAYWRIGHT_MCP_BACKGROUND=1
export PLAYWRIGHT_MCP_EXTENSION_TOKEN="$(security find-generic-password -s playwright-mcp-extension-token-profile-1 -w 2>/dev/null)"
