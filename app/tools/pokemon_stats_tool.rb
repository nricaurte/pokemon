class PokemonStatsTool < ApplicationTool
  description "Get Pokemon stats comparisons: find the strongest Pokemon by a given stat (hp, attack, defense, special-attack, special-defense, speed) or compare two Pokemon"

  arguments do
    required(:action).filled(:string).description("Action: 'top' to find strongest by stat, or 'compare' to compare two Pokemon")
    optional(:stat).filled(:string).description("Stat name: hp, attack, defense, special-attack, special-defense, or speed")
    optional(:pokemon1).filled(:string).description("First Pokemon name (for compare action)")
    optional(:pokemon2).filled(:string).description("Second Pokemon name (for compare action)")
    optional(:limit).filled(:integer).description("Number of results for 'top' action (default 10)")
  end

  def call(action:, stat: nil, pokemon1: nil, pokemon2: nil, limit: 10)
    case action.downcase
    when "top"
      top_by_stat(stat, limit)
    when "compare"
      compare_pokemon(pokemon1, pokemon2)
    else
      "Unknown action '#{action}'. Use 'top' or 'compare'."
    end
  end

  private

  def top_by_stat(stat, limit)
    return "Please provide a stat name (hp, attack, defense, special-attack, special-defense, speed)." unless stat

    all_pokemon = Pokemon.all.to_a
    sorted = all_pokemon.sort_by do |p|
      s = p.stats.find { |st| st["name"] == stat.downcase }
      s ? -s["value"] : 0
    end

    top = sorted.first(limit)
    lines = top.each_with_index.map do |p, i|
      value = p.stats.find { |s| s["name"] == stat.downcase }&.dig("value") || 0
      "#{i + 1}. ##{p.pokedex_id} #{p.name.capitalize} - #{stat}: #{value}"
    end

    "Top #{limit} Pokemon by #{stat}:\n#{lines.join("\n")}"
  end

  def compare_pokemon(name1, name2)
    return "Please provide two Pokemon names to compare." unless name1 && name2

    p1 = Pokemon.find_by(name: name1.downcase)
    p2 = Pokemon.find_by(name: name2.downcase)

    return "Pokemon '#{name1}' not found." unless p1
    return "Pokemon '#{name2}' not found." unless p2

    header = "Comparing #{p1.name.capitalize} vs #{p2.name.capitalize}:\n"
    header += "Types: #{p1.types.join(", ")} vs #{p2.types.join(", ")}\n\n"

    stat_names = p1.stats.map { |s| s["name"] }
    lines = stat_names.map do |stat|
      v1 = p1.stats.find { |s| s["name"] == stat }&.dig("value") || 0
      v2 = p2.stats.find { |s| s["name"] == stat }&.dig("value") || 0
      winner = v1 > v2 ? p1.name.capitalize : (v2 > v1 ? p2.name.capitalize : "Tie")
      "  #{stat}: #{v1} vs #{v2} (#{winner})"
    end

    total1 = p1.stats.sum { |s| s["value"] }
    total2 = p2.stats.sum { |s| s["value"] }
    total_winner = total1 > total2 ? p1.name.capitalize : (total2 > total1 ? p2.name.capitalize : "Tie")

    header + lines.join("\n") + "\n\nTotal: #{total1} vs #{total2} (#{total_winner})"
  end
end
