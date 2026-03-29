# Pokemon MCP Server

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png" width="140" alt="Charizard"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png" width="140" alt="Pikachu"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png" width="140" alt="Mewtwo"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/131.png" width="140" alt="Lapras"/>

**Habla con tus Pokemon usando Claude.**

Un servidor MCP que conecta a Claude con una base de datos de 150 Pokemon.
Pregunta por stats, compara Pokemon, filtra por tipo — todo en lenguaje natural.

</div>

---

## Que hace este proyecto?

Conecta a **Claude** (Code, Desktop o Cowork) con los datos de los primeros 150 Pokemon mediante el protocolo [MCP](https://modelcontextprotocol.io/).

```
Tu: "Cual es el Pokemon con mas HP?"
Claude: usa la herramienta PokemonStatsTool -> consulta MongoDB -> te responde
```

### Herramientas disponibles

| Herramienta | Que hace | Ejemplo |
|---|---|---|
| **SearchPokemonTool** | Busca por nombre parcial | *"Busca Pokemon que contengan 'char'"* |
| **GetPokemonTool** | Detalle completo de un Pokemon | *"Dame toda la info de Pikachu"* |
| **ListPokemonByTypeTool** | Lista Pokemon por tipo | *"Que Pokemon son de tipo fuego?"* |
| **PokemonStatsTool** | Rankings y comparaciones | *"Compara a Mewtwo con Dragonite"* |

### Ejemplo de respuesta

```
#25 Pikachu
Types: electric
Height: 0.4 m
Weight: 6.0 kg
Base Experience: 112
Abilities: static, lightning-rod (hidden)
Stats:
  hp: 35
  attack: 55
  defense: 40
  special-attack: 50
  special-defense: 50
  speed: 90
```

---

## Setup rapido

### Requisitos

- Ruby 3.4+
- MongoDB 7.0+ corriendo en `localhost:27017`
- Bundler

### Instalacion

```bash
git clone git@github.com:nricaurte/pokemon.git
cd pokemon
bundle install
rails g mongoid:config
rake pokemon:seed       # importa 150 Pokemon desde PokeAPI (~2 min)
```

Verificar:

```bash
rails runner "puts Pokemon.count"
# => 150
```

---

## Como conectar a Claude

### Opcion 1: Claude Code (local)

No necesitas hacer nada extra. El archivo `.mcp.json` ya viene configurado. Solo abre Claude Code desde el proyecto:

```bash
cd pokemon
claude
```

### Opcion 2: Claude Desktop / Cowork (local)

Agrega esto a `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "pokemon": {
      "command": "ruby",
      "args": ["mcp_server.rb"],
      "cwd": "/ruta/absoluta/a/pokemon"
    }
  }
}
```

Reinicia Claude Desktop.

### Opcion 3: Desplegado en un dominio (remoto)

Al correr `rails server` en produccion, fast-mcp expone endpoints HTTP automaticamente:

```
https://tudominio.com/mcp/messages   (JSON-RPC)
https://tudominio.com/mcp/sse        (Server-Sent Events)
```

**Desde Claude Code:**
```bash
claude mcp add --transport http pokemon https://tudominio.com/mcp
```

**Desde Claude Desktop / Cowork:**
Settings > Connectors > Add Connector > `https://tudominio.com/mcp`

### Opcion 4: Remoto con autenticacion

```bash
# En el servidor
MCP_AUTH=true MCP_TOKEN=tu-secret-token rails server

# Desde Claude Code
claude mcp add --transport http pokemon https://tudominio.com/mcp \
  --header "Authorization: Bearer tu-secret-token"
```

---

## Stack

| Tecnologia | Version | Rol |
|---|---|---|
| Ruby | 3.4.7 | Lenguaje |
| Rails | 8.1.1 | Framework (sin Active Record) |
| MongoDB | 7.0 | Base de datos |
| Mongoid | 9.0 | ODM para MongoDB |
| fast-mcp | 1.6 | Servidor MCP (stdio + HTTP/SSE) |
| HTTParty | - | Cliente HTTP para PokeAPI |

---

## Estructura del proyecto

```
app/
  models/pokemon.rb              # Modelo con campos, indices y validaciones
  services/pokemon_fetcher.rb    # Consume PokeAPI y guarda en MongoDB
  tools/
    application_tool.rb          # Clase base MCP
    search_pokemon_tool.rb       # Busqueda por nombre
    get_pokemon_tool.rb          # Detalle de Pokemon
    list_pokemon_by_type_tool.rb # Filtro por tipo
    pokemon_stats_tool.rb        # Rankings y comparaciones
config/
  initializers/fast_mcp.rb       # MCP montado en Rails (HTTP/SSE)
  mongoid.yml                    # Conexion a MongoDB
lib/tasks/pokemon.rake           # rake pokemon:seed
mcp_server.rb                    # Servidor MCP standalone (stdio)
.mcp.json                        # Config para Claude Code
CLAUDE.md                        # Documentacion tecnica detallada
```

---

## Comandos utiles

```bash
rake pokemon:seed                        # Poblar/actualizar 150 Pokemon
rails console                            # Queries manuales
rails server                             # Levantar con MCP HTTP/SSE
MCP_AUTH=true MCP_TOKEN=x rails server   # Con autenticacion
curl http://localhost:3000/up            # Health check
```

---

## Que se puede hacer desde Claude?

Una vez conectado, puedes pedirle a Claude cosas como:

<table>
<tr>
<td width="50%">

**Busquedas**
- *"Busca Pokemon que empiecen con B"*
- *"Hay algun Pokemon llamado eevee?"*
- *"Busca todos los que tengan 'saur' en el nombre"*

**Por tipo**
- *"Lista los Pokemon de tipo agua"*
- *"Cuantos Pokemon de tipo veneno hay?"*
- *"Que Pokemon son de tipo dragon?"*

</td>
<td width="50%">

**Detalle**
- *"Dame toda la info de Gengar"*
- *"Cuales son las habilidades de Snorlax?"*
- *"Que stats tiene el Pokemon #143?"*

**Comparaciones y rankings**
- *"Cual es el Pokemon mas rapido?"*
- *"Top 5 Pokemon con mas ataque"*
- *"Compara a Charizard con Blastoise"*

</td>
</tr>
</table>

---

## Quieres construir mas?

Revisa **[AGENTS.md](AGENTS.md)** — 10 ideas de agentes que puedes construir sobre este proyecto, desde un narrador de historias hasta un sistema multi-agente de soporte al cliente.

---

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png" width="80" alt="Bulbasaur"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png" width="80" alt="Charmander"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png" width="80" alt="Squirtle"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/94.png" width="80" alt="Gengar"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/143.png" width="80" alt="Snorlax"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/149.png" width="80" alt="Dragonite"/>

*Datos de [PokeAPI](https://pokeapi.co/) — Sprites de [PokeAPI/sprites](https://github.com/PokeAPI/sprites)*

</div>
