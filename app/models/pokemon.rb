class Pokemon
  include Mongoid::Document
  include Mongoid::Timestamps

  field :pokedex_id, type: Integer
  field :name, type: String
  field :height, type: Integer
  field :weight, type: Integer
  field :base_experience, type: Integer
  field :types, type: Array, default: []
  field :abilities, type: Array, default: []
  field :stats, type: Array, default: []
  field :sprite_url, type: String

  index({ pokedex_id: 1 }, { unique: true })
  index({ name: 1 })
  index({ types: 1 })

  validates :pokedex_id, presence: true, uniqueness: true
  validates :name, presence: true
end
