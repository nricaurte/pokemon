class SearchPokemonTool < ApplicationTool
  description "Search Pokemon by name (partial match supported)"

  arguments do
    required(:query).filled(:string).description("Pokemon name or partial name to search for")
  end

  def call(query:)
    results = Pokemon.where(name: /#{Regexp.escape(query)}/i).limit(20)

    if results.empty?
      return "No Pokemon found matching '#{query}'."
    end

    lines = results.map do |p|
      types = p.types.join(", ")
      "##{p.pokedex_id} #{p.name.capitalize} (#{types})"
    end

    "Found #{results.count} Pokemon matching '#{query}':\n#{lines.join("\n")}"
  end
end
