class GetPokemonTool < ApplicationTool
  description "Get detailed information about a specific Pokemon by name or Pokedex ID"

  arguments do
    required(:identifier).filled(:string).description("Pokemon name or Pokedex ID number")
  end

  def call(identifier:)
    pokemon = if identifier.match?(/\A\d+\z/)
      Pokemon.find_by(pokedex_id: identifier.to_i)
    else
      Pokemon.find_by(name: identifier.downcase)
    end

    unless pokemon
      return "Pokemon '#{identifier}' not found."
    end

    types = pokemon.types.join(", ")
    abilities = pokemon.abilities.map { |a| a["is_hidden"] ? "#{a["name"]} (hidden)" : a["name"] }.join(", ")
    stats = pokemon.stats.map { |s| "  #{s["name"]}: #{s["value"]}" }.join("\n")

    <<~INFO
      ##{pokemon.pokedex_id} #{pokemon.name.capitalize}
      Types: #{types}
      Height: #{pokemon.height / 10.0} m
      Weight: #{pokemon.weight / 10.0} kg
      Base Experience: #{pokemon.base_experience}
      Abilities: #{abilities}
      Stats:
      #{stats}
      Sprite: #{pokemon.sprite_url}
    INFO
  end
end
