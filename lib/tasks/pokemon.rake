namespace :pokemon do
  desc "Seed the database with the first 150 Pokemon from PokeAPI"
  task seed: :environment do
    puts "Fetching Pokemon from PokeAPI..."
    PokemonFetcher.fetch_all(limit: 150) do |id|
      print "\rFetched #{id}/150"
    end
    puts "\nDone! #{Pokemon.count} Pokemon stored in MongoDB."
  end
end
