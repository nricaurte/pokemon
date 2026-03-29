class ListPokemonByTypeTool < ApplicationTool
  description "List all Pokemon of a given type (e.g., fire, water, grass, electric)"

  arguments do
    required(:type).filled(:string).description("Pokemon type such as fire, water, grass, electric, psychic, etc.")
  end

  def call(type:)
    results = Pokemon.where(types: type.downcase).order_by(pokedex_id: :asc)

    if results.empty?
      return "No Pokemon found with type '#{type}'."
    end

    lines = results.map do |p|
      types = p.types.join(", ")
      "##{p.pokedex_id} #{p.name.capitalize} (#{types})"
    end

    "Found #{results.count} #{type.capitalize}-type Pokemon:\n#{lines.join("\n")}"
  end
end
