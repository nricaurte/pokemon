#!/usr/bin/env ruby
Dir.chdir(__dir__)
require_relative "config/environment"

server = FastMcp::Server.new(name: "pokemon-mcp", version: "1.0.0")
server.register_tools(
  SearchPokemonTool,
  GetPokemonTool,
  ListPokemonByTypeTool,
  PokemonStatsTool
)
server.start
