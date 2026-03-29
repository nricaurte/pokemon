require "fast_mcp"

FastMcp.mount_in_rails(
  Rails.application,
  name: "pokemon-mcp",
  version: "1.0.0",
  authenticate: ENV.fetch("MCP_AUTH", "false") == "true",
  auth_token: ENV["MCP_TOKEN"]
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(*ApplicationTool.descendants)
  end
end
