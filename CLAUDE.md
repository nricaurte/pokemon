# Pokemon MCP Server

App Rails que consume la PokeAPI, almacena datos en MongoDB y expone un servidor MCP para que Claude pueda consultar información de Pokemon.

## Stack

- **Ruby 3.4.7** / **Rails 8.1.1**
- **MongoDB 7.0** + **Mongoid 9** (ODM, reemplaza Active Record)
- **PokeAPI** (https://pokeapi.co/api/v2/)
- **fast-mcp 1.6** (servidor MCP con transporte stdio y HTTP/SSE)
- **HTTParty** (cliente HTTP para consumir PokeAPI)

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Claude (Code / Desktop / Cowork)  │
│                                                     │
│  "Busca Pokemon de tipo fuego"                      │
└──────────────┬──────────────────────────────────────┘
               │  MCP Protocol (stdio o HTTP/SSE)
               ▼
┌─────────────────────────────────────────────────────┐
│              MCP Server (fast-mcp 1.6)              │
│                                                     │
│  Modo stdio  → mcp_server.rb                        │
│  Modo HTTP   → config/initializers/fast_mcp.rb      │
│               (montado en Rails, endpoints /mcp/*)  │
│                                                     │
│  Tools registrados:                                 │
│  ┌────────────────────┐  ┌───────────────────────┐  │
│  │ SearchPokemonTool  │  │ GetPokemonTool        │  │
│  │ Búsqueda parcial   │  │ Detalle por nombre/ID │  │
│  └────────────────────┘  └───────────────────────┘  │
│  ┌────────────────────────┐ ┌─────────────────────┐ │
│  │ ListPokemonByTypeTool  │ │ PokemonStatsTool    │ │
│  │ Filtrar por tipo       │ │ Top N / Comparar    │ │
│  └────────────────────────┘ └─────────────────────┘ │
└──────────────┬──────────────────────────────────────┘
               │  Mongoid ODM
               ▼
┌─────────────────────────────────────────────────────┐
│              MongoDB 7.0                            │
│  DB: pokemon_mcp_development                        │
│  Colección: pokemons (150 documentos)               │
│                                                     │
│  Índices: pokedex_id (unique), name, types          │
└─────────────────────────────────────────────────────┘

Poblar datos:
┌──────────────┐    HTTParty     ┌────────────────────┐
│ rake task    │ ──────────────► │ pokeapi.co/api/v2  │
│ pokemon:seed │ ◄────────────── │ (150 Pokemon)      │
└──────┬───────┘    JSON         └────────────────────┘
       │ upsert
       ▼
    MongoDB
```

## Estructura de archivos clave

```
pokemon_mcp/
├── mcp_server.rb                          # Servidor MCP standalone (stdio)
├── .mcp.json                              # Config MCP para Claude Code
├── app/
│   ├── models/
│   │   └── pokemon.rb                     # Modelo Mongoid
│   ├── services/
│   │   └── pokemon_fetcher.rb             # Consumidor de PokeAPI
│   └── tools/
│       ├── application_tool.rb            # Base class (hereda FastMcp::Tool)
│       ├── search_pokemon_tool.rb         # Buscar por nombre parcial
│       ├── get_pokemon_tool.rb            # Detalle de un Pokemon
│       ├── list_pokemon_by_type_tool.rb   # Listar por tipo
│       └── pokemon_stats_tool.rb          # Top stats / comparar Pokemon
├── config/
│   ├── initializers/
│   │   └── fast_mcp.rb                   # MCP montado en Rails (HTTP/SSE)
│   └── mongoid.yml                        # Conexión a MongoDB
└── lib/
    └── tasks/
        └── pokemon.rake                   # rake pokemon:seed
```

## Modelo de datos (MongoDB)

Colección `pokemons`, documento ejemplo:

```json
{
  "pokedex_id": 25,
  "name": "pikachu",
  "height": 4,
  "weight": 60,
  "base_experience": 112,
  "types": ["electric"],
  "abilities": [
    { "name": "static", "is_hidden": false },
    { "name": "lightning-rod", "is_hidden": true }
  ],
  "stats": [
    { "name": "hp", "value": 35 },
    { "name": "attack", "value": 55 },
    { "name": "defense", "value": 40 },
    { "name": "special-attack", "value": 50 },
    { "name": "special-defense", "value": 50 },
    { "name": "speed", "value": 90 }
  ],
  "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png",
  "created_at": "2026-03-28T...",
  "updated_at": "2026-03-28T..."
}
```

Unidades: `height` en decímetros, `weight` en hectogramos.

## Herramientas MCP disponibles

| Tool | Descripción | Argumentos |
|------|-------------|------------|
| **SearchPokemonTool** | Busca Pokemon por nombre parcial | `query` (string) |
| **GetPokemonTool** | Detalle completo de un Pokemon | `identifier` (nombre o ID) |
| **ListPokemonByTypeTool** | Lista Pokemon por tipo | `type` (fire, water, grass...) |
| **PokemonStatsTool** | Rankings y comparaciones | `action` (top/compare), `stat`, `pokemon1`, `pokemon2`, `limit` |

## Setup inicial

Requiere MongoDB corriendo en `localhost:27017`.

```bash
cd pokemon_mcp
bundle install
rails g mongoid:config          # solo la primera vez
rake pokemon:seed               # importa 150 Pokemon desde PokeAPI
```

Verificar:
```bash
rails runner "puts Pokemon.count"   # debe imprimir 150
```

## Conexión a Claude según escenario

### 1. Local con Claude Code (stdio)

No requiere config adicional. El archivo `.mcp.json` en la raíz del proyecto lo configura automáticamente:

```json
{
  "mcpServers": {
    "pokemon": {
      "command": "ruby",
      "args": ["mcp_server.rb"]
    }
  }
}
```

Iniciar Claude Code desde el directorio del proyecto:
```bash
cd pokemon_mcp
claude
```

### 2. Local con Claude Desktop / Cowork (stdio)

Agregar al archivo `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "pokemon": {
      "command": "ruby",
      "args": ["mcp_server.rb"],
      "cwd": "/ruta/absoluta/a/pokemon_mcp"
    }
  }
}
```

Reiniciar Claude Desktop para que tome efecto.

### 3. Remoto desplegado en un dominio (HTTP/SSE)

Al hacer deploy y correr `rails server`, fast-mcp expone automáticamente:
- `https://tudominio.com/mcp/messages` — JSON-RPC
- `https://tudominio.com/mcp/sse` — Server-Sent Events

**Desde Claude Code:**
```bash
claude mcp add --transport http pokemon https://tudominio.com/mcp
```

**Desde Claude Desktop / Cowork:**
Settings → Connectors → Add Connector → `https://tudominio.com/mcp`

### 4. Remoto con autenticación

Setear variables de entorno en el servidor:
```bash
MCP_AUTH=true MCP_TOKEN=tu-secret-token rails server
```

**Desde Claude Code:**
```bash
claude mcp add --transport http pokemon https://tudominio.com/mcp \
  --header "Authorization: Bearer tu-secret-token"
```

**Desde Claude Desktop / Cowork:**
Configurar el token en el flujo de autenticación del connector.

## Comandos útiles

```bash
# Seed / re-seed (idempotente por upsert)
rake pokemon:seed

# Consola Rails para queries manuales
rails console
> Pokemon.where(types: "fire").count
> Pokemon.find_by(name: "pikachu")

# Probar MCP server manualmente (envía initialize y tools/list)
printf '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}\n{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n{"jsonrpc":"2.0","method":"tools/list","id":2}\n' | ruby mcp_server.rb

# Levantar Rails con MCP HTTP/SSE
rails server

# Levantar con autenticación MCP
MCP_AUTH=true MCP_TOKEN=secreto rails server

# Health check
curl http://localhost:3000/up
```

## Convenciones del proyecto

- Las herramientas MCP van en `app/tools/` y heredan de `ApplicationTool`
- Los servicios van en `app/services/`
- Rails autoload maneja `app/tools/` y `app/services/` sin config extra
- `mcp_server.rb` usa `Dir.chdir(__dir__)` para resolver rutas relativas — funciona desde cualquier directorio
- El seed es idempotente: usa `find_or_initialize_by` para evitar duplicados
