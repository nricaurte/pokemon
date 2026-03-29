class PokemonFetcher
  BASE_URL = "https://pokeapi.co/api/v2/pokemon"

  def self.fetch_and_store(id)
    response = HTTParty.get("#{BASE_URL}/#{id}")
    return nil unless response.success?

    data = response.parsed_response

    types = data["types"].map { |t| t["type"]["name"] }
    abilities = data["abilities"].map do |a|
      { "name" => a["ability"]["name"], "is_hidden" => a["is_hidden"] }
    end
    stats = data["stats"].map do |s|
      { "name" => s["stat"]["name"], "value" => s["base_stat"] }
    end
    sprite_url = data.dig("sprites", "front_default")

    Pokemon.find_or_initialize_by(pokedex_id: data["id"]).tap do |pokemon|
      pokemon.assign_attributes(
        name: data["name"],
        height: data["height"],
        weight: data["weight"],
        base_experience: data["base_experience"],
        types: types,
        abilities: abilities,
        stats: stats,
        sprite_url: sprite_url
      )
      pokemon.save!
    end
  end

  def self.fetch_all(limit: 150)
    (1..limit).each do |id|
      fetch_and_store(id)
      yield id if block_given?
    end
  end
end
