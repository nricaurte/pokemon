# 10 Ideas de Agentes con MCP

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png" width="120" alt="Mewtwo"/>

**De tools simples a agentes inteligentes.**

</div>

---

## Como funciona: Tools vs Agentes

### Que pasa cuando conectas un servidor MCP?

Cuando Claude se conecta a tu servidor MCP (ya sea por `.mcp.json`, Claude Desktop o `claude mcp add`), hace un descubrimiento automatico:

```
1. Claude envia "initialize" al servidor MCP
2. Claude llama "tools/list" y recibe todas las herramientas disponibles
3. Claude lee el nombre, descripcion y argumentos de cada tool
4. Claude ya sabe cuando y como usarlas
```

**La clave:** la `description` que pones en cada tool es lo que Claude lee para decidir cuando usarla. Una buena descripcion = Claude la usa en el momento correcto.

### Que construyes tu vs que hace Claude

| Tu construyes | Claude hace solo |
|---|---|
| MCP tools en Ruby (logica de datos) | Decidir cuando usar cada tool |
| Modelos MongoDB (esquema) | Encadenar multiples tools en secuencia |
| Servidor MCP (transporte) | Interpretar y formatear resultados |
| Descripciones claras en cada tool | Responder en lenguaje natural |

### Tools MCP vs Agent SDK: cuando necesitas que?

| Solo Tools MCP | Agente (Claude Agent SDK) |
|---|---|
| Claude decide en el momento | Logica predefinida y especializada |
| Una conversacion, un flujo | Estado persistente entre turnos (score, HP, ELO) |
| Un solo servidor MCP | Orquesta multiples MCP servers en paralelo |
| Claude es el agente | Sub-agentes especializados con roles distintos |
| Sin automatizacion | Puede correr en background, headless, scheduled |

**En resumen:** al agregar tools MCP, Claude ya actua como agente basico. El Agent SDK es para cuando necesitas sub-agentes coordinados, estado complejo o automatizacion.

### 3 formas de usar estos agentes

**1. Claude Code (terminal)**
```bash
cd pokemon_mcp && claude
Tu: "Arma un equipo competitivo alrededor de Charizard"
```

**2. Claude Desktop / Cowork (app grafica)**
Conectas el MCP server y hablas en lenguaje natural desde la app.

**3. App web propia (para ideas avanzadas)**
Frontend (React, Rails views) que se comunica con Claude Agent SDK en el backend.

---

## Las 10 Ideas

---

### 1. PokeTeam Builder

> Arma equipos competitivos de 6 Pokemon balanceados por tipo y stats.

**Problema:** Construir un equipo balanceado requiere analizar coberturas de 18 tipos y 6 stats simultaneamente. Es abrumador hacerlo manualmente.

**Nivel:** Medio | **Tiempo:** 4-5 dias (manual) / 4-6 horas (con Claude) | **Requiere Agent SDK:** No

```
Usuario: "Arma un equipo alrededor de Gengar y Gyarados"
         |
         v
  Claude (usando MCP tools)
         |
    +----+----+----+
    |         |         |
    v         v         v
 GetPokemon  ListByType  PokemonStats
 (anclas)    (candidatos) (comparar)
    |         |         |
    v         v         v
         TeamAnalysisTool  <-- NUEVO
         (cobertura tipos)
         |
         v
  "Tu equipo: Gengar, Gyarados, Rhydon,
   Alakazam, Jolteon, Snorlax.
   Cobertura: 15/18 tipos. Debilidad
   compartida: solo Ground."
```

**Tools existentes:** GetPokemon, ListByType, PokemonStats
**Tool nuevo:** `TeamAnalysisTool` — recibe array de 6 Pokemon, retorna matriz de cobertura ofensiva/defensiva, debilidades compartidas y distribucion de stats.

**Ejemplo:**
- *"Quiero un equipo centrado en Gengar y Gyarados. Que sea balanceado."*
- Claude analiza que Ghost/Poison + Water/Flying deja huecos en Ground, Electric, Psychic.
- Completa con Rhydon (Ground/Rock), Alakazam (Psychic), Jolteon (Electric), Snorlax (Normal tank).
- Valida con TeamAnalysisTool: 15/18 tipos cubiertos, promedio stats 510.

---

### 2. PokeDex Narrador

> Transforma datos crudos en historias: cronicas de batalla, lore, cuentos para dormir.

**Problema:** Los stats de Pokemon son numeros secos. Este agente los convierte en narrativas entretenidas usando datos reales para que las historias sean precisas.

**Nivel:** Facil | **Tiempo:** 2-3 dias (manual) / 2-3 horas (con Claude) | **Requiere Agent SDK:** No

```
Usuario: "Cuenta una pelea entre Mewtwo y Dragonite
          al estilo de cronica deportiva"
         |
         v
  Claude (con system prompt de narrador)
         |
    +----+----+
    |         |
    v         v
 GetPokemon  PokemonStats
 (datos)     (compare)
    |         |
    v         v
  "ROUND 1 -- Suena la campana y Mewtwo
   ataca primero! Con 130 de velocidad,
   el titan psiquico se mueve antes de
   que Dragonite parpadee. Un devastador
   Psychic impulsado por 154 de special-
   attack impacta contra los 100 de
   special-defense de Dragonite..."
```

**Tools existentes:** GetPokemon, PokemonStats (compare)
**Tools nuevos:** Ninguno — solo un agente con buen system prompt de narrador

**Modos de narrativa:**
- `lore_entry` — entrada de Pokedex expandida
- `battle_story` — cronica de combate
- `origin_tale` — historia de origen del Pokemon
- `day_in_the_life` — un dia normal de un Pokemon

---

### 3. Pokemon Data Analyst

> Agente de BI que responde preguntas analiticas sobre el dataset.

**Problema:** Extraer insights de datos requiere escribir queries y saber que buscar. Este agente es un analista de datos que habla espanol.

**Nivel:** Medio | **Tiempo:** 5-6 dias (manual) / 1 dia (con Claude) | **Requiere Agent SDK:** No

```
Usuario: "Hay correlacion entre peso y defensa?"
         |
         v
  Claude (analista de datos)
         |
    +----+----+----+
    |         |         |
    v         v         v
 ListByType  PokemonStats  AggregateStats  <-- NUEVO
 (segmentar) (rankings)    (correlacion,
                            promedios,
                            distribuciones)
         |
         v
  "Correlacion peso vs defensa: r=0.62
   (moderada positiva). Los Pokemon mas
   pesados tienden a tener mas defensa.
   Outlier notable: Onix (peso 2100hg,
   defensa 160) vs Chansey (346hg, def 5)"
```

**Tools existentes:** PokemonStats, ListByType
**Tool nuevo:** `AggregateStatsTool` — ejecuta pipelines de agregacion MongoDB. Argumentos: `analysis_type` (average | distribution | correlation | type_breakdown), `stat1`, `stat2` (para correlacion), `group_by`.

**Tipos de preguntas que responde:**
- *"Cual es el tipo mas fuerte en promedio?"*
- *"Dame la distribucion de HP en los 150 Pokemon"*
- *"Que correlacion hay entre velocidad y ataque?"*
- *"Reporte ejecutivo del dataset completo"*

**Patron replicable:** Este mismo tool funciona para cualquier coleccion MongoDB (ventas, usuarios, productos).

---

### 4. PokeTrivia Arena

> Juego de trivia con preguntas generadas dinamicamente desde datos reales.

**Problema:** La gamificacion impulsa el engagement. Las preguntas se generan desde datos reales, no hardcodeadas, asi que cada sesion es unica.

**Nivel:** Medio | **Tiempo:** 4-5 dias (manual) / 4-6 horas (con Claude) | **Requiere Agent SDK:** No (pero mejora con el)

```
Usuario: "Juguemos trivia Pokemon, dificultad dificil"
         |
         v
  Claude (game master)
  Estado: { score: 0, round: 1, streak: 0 }
         |
    +----+----+----+
    |         |         |
    v         v         v
 RandomPokemon GetPokemon PokemonStats
 (4 al azar)  (datos)    (verificar)
    |              <-- NUEVO
    v
  "Pregunta 1/5 (DIFICIL):
   Ordena de mayor a menor special-attack:
   Alakazam, Nidoking, Jynx, Tentacruel"

  Usuario: "Alakazam, Jynx, Nidoking, Tentacruel"

  "CORRECTO! Alakazam(135) > Jynx(115) >
   Nidoking(85) > Tentacruel(80).
   Score: 1/1. Racha: 1"
```

**Tools existentes:** GetPokemon, PokemonStats, ListByType, SearchPokemon
**Tool nuevo:** `RandomPokemonTool` — retorna N Pokemon aleatorios usando MongoDB `$sample`. Argumento: `count` (integer, default 1).

**Tipos de preguntas generadas:**
- Ordenar por stat (dificil)
- "Quien tiene mas X, A o B?" (medio)
- "De que tipo es X?" (facil)
- "Cuantos Pokemon de tipo Y hay?" (medio)
- "Verdadero o falso: X pesa mas que Y" (facil)

**Aplicacion de negocio:** Mismo patron para quizzes de onboarding, capacitacion de producto, evaluaciones.

---

### 5. PokeScholar — Multi-Source Research

> Combina 3 servidores MCP en paralelo: DB local + PokeAPI live + web search.

**Problema:** La investigacion real requiere sintetizar multiples fuentes desconectadas. Este agente demuestra la killer feature de MCP: composicion de herramientas de diferentes servidores.

**Nivel:** Avanzado | **Tiempo:** 7-8 dias (manual) / 2-3 dias (con Claude) | **Requiere Agent SDK:** Recomendado

```
Usuario: "Research brief completo sobre Eevee"
         |
         v
  Claude (investigador)
         |
    +----+----+----+
    |         |         |
    v         v         v
 MCP #1:     MCP #2:      MCP #3:
 pokemon     pokeapi-live  web-search
 (DB local)  (API live)    (internet)
    |         |              |
    v         v              v
 Stats base  Evoluciones   Meta competitivo
 Types       Movimientos   Anime, cultura
 Abilities   Flavor text   Merchandise
    |         |              |
    +----+----+----+
         |
         v
  "RESEARCH BRIEF: EEVEE (#133)
   Stats: Normal, 325 BST, balanced...
   Evoluciones: 3 en Gen 1 (Vaporeon,
   Jolteon, Flareon), 8 en total...
   Meta 2026: Vaporeon sigue siendo el
   mas fuerte en formatos Gen 1...
   Impacto cultural: 2do Pokemon mas
   merchandised despues de Pikachu..."
```

**MCP servers:**
- `pokemon` (existente) — stats base desde MongoDB
- `pokeapi-live` (nuevo, Ruby) — wraps PokeAPI endpoints no cacheados: `/evolution-chain/`, `/pokemon-species/`
- `web-search` (community) — Brave Search o Tavily MCP server

**Tools nuevos en `pokeapi-live` server:**
- `GetEvolutionChainTool` — cadena evolutiva completa
- `GetMovesTool` — moveset del Pokemon
- `GetSpeciesFlavorTool` — flavor text y habitat

**Patron replicable:** DB interna + API externa + web = patron universal de research para cualquier negocio.

---

### 6. InfraGuardian — DevOps Multi-Agent

> Sistema multi-agente para monitoreo de infraestructura con 3 sub-agentes especializados.

**Problema:** Los equipos de DevOps se ahogan en alertas de multiples sistemas sin una capa de inteligencia unificada.

**Nivel:** Avanzado | **Tiempo:** 10-12 dias (manual) / 3-4 dias (con Claude) | **Requiere Agent SDK:** Si (multi-agent)

```
Usuario: "Como esta nuestra infraestructura?"
         |
         v
  +--------------------------------------+
  |  Lead Agent: InfraGuardian           |
  |  (orquesta y correlaciona)           |
  +------+----------+----------+--------+
         |          |          |
         v          v          v
  +-----------+ +---------+ +-----------+
  | SubAgent: | |SubAgent:| | SubAgent: |
  | Uptime    | | Logs    | | Deploy    |
  +-----------+ +---------+ +-----------+
       |            |            |
       v            v            v
  +-----------+ +---------+ +-----------+
  | MCP:      | | MCP:    | | MCP:      |
  | health-   | | logs-   | | deploy-   |
  | check     | | mcp     | | mcp       |
  +-----------+ +---------+ +-----------+
       |            |            |
       v            v            v
  [endpoints]  [log files]  [containers]
         |
         v
  "INFRASTRUCTURE HEALTH: HEALTHY
   Uptime: Rails en 43ms en /up
   Logs: 0 errores, 3 deprecation warnings
   Containers: 2/2 running (rails + mongo)
   Ultimo deploy: hace 2h, exitoso
   Recomendacion: atender 3 warnings
   antes del proximo upgrade de Rails"
```

**3 MCP servers nuevos (Ruby):**
- `health-check-mcp`: tools `PingEndpointTool`, `CheckSslTool`, `MeasureResponseTimeTool`
- `logs-mcp`: tools `TailLogsTool`, `SearchErrorsTool`, `CountByLevelTool`
- `deploy-mcp`: tools `DeploymentStatusTool`, `ContainerHealthTool`, `RecentDeploysTool`

**Stack adicional:** Claude Agent SDK (TypeScript) con `subagents`. Cada sub-agente tiene su propio MCP server y contexto.

---

### 7. ProductSensei — E-Commerce Advisor

> Demuestra que el patron Pokemon MCP sirve para cualquier catalogo de productos.

**Problema:** Las tiendas online tienen catalogos con atributos, categorias y specs — exactamente como nuestra coleccion de Pokemon. Mismo patron, diferentes datos.

**Nivel:** Medio | **Tiempo:** 3-8 dias (manual) / 1-3 dias (con Claude) | **Requiere Agent SDK:** No

```
FASE 1: Pokemon como productos (demo)
=========================================
Usuario: "Necesito un Pokemon rapido con buen
          ataque especial, que no sea agua"
         |
         v
  Claude (consultor de productos)
         |
    +----+----+
    |         |
    v         v
 PokemonStats  ListByType
 (top speed    (excluir
  + top SpAtk)  water)
         |
         v
  "Top 3 recomendaciones:
   1. Alakazam — Spd 120, SpAtk 135
   2. Gengar — Spd 110, SpAtk 130
   3. Jolteon — Spd 130, SpAtk 110
   Mi pick: Alakazam si necesitas poder,
   Jolteon si priorizas velocidad"

FASE 2: Datos reales de e-commerce
=========================================
Mismos tools, diferente modelo MongoDB:
  Pokemon    →  Product
  types      →  categories
  stats      →  specs (RAM, storage, price...)
  abilities  →  features
```

**Fase 1:** Usa tools existentes de Pokemon MCP. Zero code nuevo.
**Fase 2:** Nuevo modelo `Product` + tools espejo: `SearchProductTool`, `GetProductTool`, `ListByCategoryTool`, `CompareProductsTool`, `FilterByPriceTool`.

---

### 8. PokeBattle Simulator

> Simulador de batallas turno a turno con formula de dano Gen 1 real.

**Problema:** Imaginar el resultado de una batalla requiere calcular efectividad de tipos, diferencias de stats y multiplicadores. Este agente lo simula turno a turno.

**Nivel:** Avanzado | **Tiempo:** 6-7 dias (manual) / 1-2 dias (con Claude) | **Requiere Agent SDK:** Recomendado (estado de batalla)

```
Usuario: "Simula Charizard vs Blastoise, turno a turno"
         |
         v
  Claude (simulador de combate)
  Estado: { turn: 1, p1_hp: 78, p2_hp: 79 }
         |
    +----+----+----+
    |         |         |
    v         v         v
 GetPokemon  TypeEffect  DamageCalc
 (ambos)     ivenessTool ulatorTool
             <-- NUEVO   <-- NUEVO
         |
         v
  "BATALLA: Charizard vs Blastoise

   Turno 1: Charizard es mas rapido
   (Spd 100 vs 78) y ataca primero!
   Solar Beam (Grass, 120) → super
   efectivo x2 vs Water! Dano: 68.
   Blastoise HP: 79 → 11.

   Blastoise contraataca con Hydro Pump
   (Water, 110) → SUPER EFECTIVO x4
   vs Fire/Flying! Dano: 142.
   Charizard HP: 78 → 0. KO!

   GANADOR: Blastoise en 1 turno.
   La ventaja de tipo fue decisiva."
```

**Tools existentes:** GetPokemon
**Tools nuevos:**
- `TypeEffectivenessTool` — matriz 15x15 de tipos Gen 1 hardcodeada. Recibe `attack_type` + `defender_types`, retorna multiplicador (0, 0.5, 1, 2).
- `DamageCalculatorTool` — formula de dano Gen 1: `((2*50/5+2)*Power*A/D)/50+2)*Modifier`. Recibe stats de atacante/defensor, poder del movimiento, efectividad, STAB.

---

### 9. SupportSquad — Customer Support A2A

> Sistema multi-agente de soporte: Router clasifica y delega a sub-agentes especializados.

**Problema:** El soporte al cliente requiere diferentes expertise: producto, pedidos, facturacion. Un solo agente no puede manejar todo eficientemente.

**Nivel:** Avanzado | **Tiempo:** 10-14 dias (manual) / 3-5 dias (con Claude) | **Requiere Agent SDK:** Si (multi-agent A2A)

```
Cliente: "Compre un Pikachu plush pero
          me llego un Charmander"
         |
         v
  +-------------------------------------+
  |  Router Agent: SupportSquad Lead    |
  |  Clasifica: order_issue +           |
  |  product_mismatch + exchange        |
  +------+-----------+-----------+------+
         |           |           |
         v           v           v
  +-----------+ +-----------+ +-----------+
  | SubAgent: | | SubAgent: | | SubAgent: |
  | Product   | | Order     | | Billing   |
  | Expert    | | Tracker   | | Agent     |
  +-----------+ +-----------+ +-----------+
       |             |             |
       v             v             v
  +-----------+ +-----------+ +-----------+
  | MCP:      | | MCP:      | | MCP:      |
  | pokemon   | | orders-   | | billing-  |
  | (catalogo)| | mcp       | | mcp       |
  +-----------+ +-----------+ +-----------+
       |             |             |
       v             v             v
  [Pokemon DB] [Orders DB]  [Billing DB]
         |
         v
  "Identifique el problema con tu orden
   #789. Pediste Pikachu (#25, Electric)
   pero recibiste Charmander (#4, Fire).
   Ya inicie el cambio:
   1. Etiqueta de devolucion enviada
   2. Nuevo Pikachu en camino (express)
   3. Sin cargos adicionales
   Entrega estimada: 2-3 dias."
```

**MCP servers:**
- `pokemon` (existente) — sirve como catalogo de productos
- `orders-mcp` (nuevo): `GetOrderTool`, `ListOrdersByCustomerTool`, `UpdateOrderStatusTool`
- `billing-mcp` (nuevo): `ProcessRefundTool`, `GetPaymentHistoryTool`, `CreateCreditTool`

**Modelos Mongoid nuevos:** `Order`, `Customer`, `Payment`

**Patron A2A:** El Router Agent no resuelve nada — solo clasifica intent y delega. Cada sub-agente tiene su propio contexto y MCP server.

---

### 10. PokeLeague — Torneo con ELO

> Sistema de torneos con brackets, simulacion de matches y ranking ELO persistente.

**Problema:** Correr torneos, trackear rankings y mantener un leaderboard ELO requiere estado persistente y workflows multi-paso.

**Nivel:** Avanzado | **Tiempo:** 8-10 dias (manual) / 2-3 dias (con Claude) | **Requiere Agent SDK:** Recomendado

```
Usuario: "Crea un torneo de 8 Pokemon aleatorios
          y simulalo completo"
         |
         v
  Claude (comisionado de liga)
         |
    +----+----+----+----+
    |         |         |         |
    v         v         v         v
 Random    GetPoke   Pokemon   League
 Pokemon   mon       Stats     Tool
 Tool      (datos)   (seeding) (brackets,
 (8 azar)                       ELO)
                                <-- NUEVO
         |
         v
  "RANDOM CUP #1 — RESULTADOS

   Cuartos de final:
   [1] Dragonite def. [8] Pikachu
   [4] Snorlax def. [5] Alakazam
   [3] Gengar def. [6] Venusaur
   [7] Blastoise def. [2] Charizard

   Semifinales:
   Dragonite def. Snorlax
   Blastoise def. Gengar

   FINAL:
   Dragonite def. Blastoise

   CAMPEON: DRAGONITE

   ELO Updates:
   Dragonite 1000→1096
   Blastoise 1000→1060
   Gengar    1000→1028
   ...
   Pikachu   1000→968"
```

**Tools existentes:** GetPokemon, PokemonStats
**Tools nuevos:**
- `RandomPokemonTool` (compartido con idea #4)
- `LeagueTool` — acciones: `create_tournament`, `get_bracket`, `record_match`, `get_rankings`, `get_season_history`

**Modelos Mongoid nuevos:**
- `League` (name, status, bracket_data)
- `Match` (league_id, round, pokemon1, pokemon2, winner, elo_change)
- `Ranking` (pokemon_name, elo_rating, wins, losses)

**Aplicacion de negocio:** Mismo patron para leaderboards de ventas, gamificacion de empleados, rankings competitivos.

---

## Resumen

| # | Nombre | Dificultad | Manual | Con Claude | Agent SDK | Tools nuevos |
|---|--------|-----------|--------|-----------|-----------|-------------|
| 1 | PokeTeam Builder | Medio | 4-5d | 4-6h | No | TeamAnalysisTool |
| 2 | PokeDex Narrador | Facil | 2-3d | 2-3h | No | Ninguno |
| 3 | Pokemon Data Analyst | Medio | 5-6d | 1d | No | AggregateStatsTool |
| 4 | PokeTrivia Arena | Medio | 4-5d | 4-6h | Opcional | RandomPokemonTool |
| 5 | PokeScholar | Avanzado | 7-8d | 2-3d | Recomendado | 3 tools + nuevo MCP server |
| 6 | InfraGuardian | Avanzado | 10-12d | 3-4d | Si | 9 tools + 3 MCP servers |
| 7 | ProductSensei | Medio | 3-8d | 1-3d | No | 5 tools (Fase 2) |
| 8 | PokeBattle Simulator | Avanzado | 6-7d | 1-2d | Recomendado | TypeEffectiveness + DamageCalc |
| 9 | SupportSquad | Avanzado | 10-14d | 3-5d | Si | 6 tools + 2 MCP servers |
| 10 | PokeLeague | Avanzado | 8-10d | 2-3d | Recomendado | LeagueTool + RandomPokemon |

> **Por que la diferencia?** Claude genera los tools Ruby, modelos Mongoid, configuracion MCP y tests — que es el 70-80% del trabajo. Lo que queda es revisar, ajustar logica de negocio y probar.

## Orden recomendado de construccion

```
Con Claude:

Dia 1:     PokeDex Narrador (2-3h) → victoria rapida
           PokeTrivia Arena (4-6h) → agrega RandomPokemonTool

Dia 2:     PokeTeam Builder (4-6h) → demuestra tool chaining

Dia 3-4:   PokeBattle Simulator (1-2d) → demo impresionante

Dia 5-7:   PokeScholar (2-3d) → multi-MCP, factor "wow"

Dia 8-12:  SupportSquad (3-5d) → patron de negocio real con A2A
```

```
Manual (sin Claude):

Semana 1:  PokeDex Narrador (2-3d) + PokeTrivia Arena (4-5d)
Semana 2:  PokeTeam Builder (4-5d) + PokeBattle Simulator (6-7d)
Semana 3:  PokeScholar (7-8d)
Semana 4+: SupportSquad (10-14d)
```

---

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/68.png" width="80" alt="Machamp"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/65.png" width="80" alt="Alakazam"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/94.png" width="80" alt="Gengar"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/130.png" width="80" alt="Gyarados"/>
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/149.png" width="80" alt="Dragonite"/>

*Construido sobre [Pokemon MCP Server](README.md) — Datos de [PokeAPI](https://pokeapi.co/)*

</div>
