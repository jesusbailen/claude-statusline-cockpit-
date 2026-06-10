# Claude Code Statusline Cockpit

Statusline personalizado de dos lineas para [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que te da visibilidad en tiempo real sobre tu sesion, proyecto y rate limits directamente en el terminal.

```
Claude Opus 4.6 | 5h: 12% (4h32m) | 7d: 3% (6d11h) | ctx: 8% | ⎇ main
✓ limpio  │  WP 6.7 · PHP 8.2 · wp-cli ✓  │  mcp: 3  │  ~/myproject
```

## Como funciona

El statusline se divide en dos scripts que trabajan juntos:

### `statusline-cockpit.sh` (punto de entrada)

Lee el JSON que Claude Code inyecta en el comando de statusline y renderiza dos lineas:

**Linea 1** — delega en `statusline-legacy.sh`:
- Nombre del modelo activo (ej. `Claude Opus 4.6`)
- Uso de rate limits en ambas ventanas (`5h` y `7d`) con cuenta atras hasta el reset
- Uso de la ventana de contexto (`ctx`)
- Rama git actual (`⎇ main`)

**Linea 2** — ensamblada por el cockpit:
- **Estado git**: `✓ clean` o `✱N changes` (amarillo) — numero de archivos sucios via `git status --porcelain`
- **Deteccion de stack**: detecta automaticamente el framework del proyecto buscando archivos marcadores:
  - `wp-config.php` / `wp-content/` → WordPress (+ version desde `wp-includes/version.php`, version de PHP, disponibilidad de wp-cli)
  - `artisan` → Laravel
  - `core/lib/Drupal.php` → Drupal
  - `configuration.php` + `administrator/` → Joomla
  - `next.config.{js,mjs,ts}` → Next.js
  - `package.json` → Node (+ version)
  - `pyproject.toml` / `requirements.txt` → Python
- **Servidores MCP**: cuenta servidores del `.mcp.json` del proyecto y del `~/.claude.json` global
- **Directorio de trabajo**: abreviado con `~`

Todos los segmentos se separan con `│` y se colorean con codigos ANSI.

### `statusline-legacy.sh`

Script Python envuelto en bash que parsea el JSON de entrada de Claude Code y renderiza la linea 1. Gestiona:
- Nombre del modelo desde `model.display_name` o `model.id`
- Dos ventanas de rate limit (`five_hour`, `seven_day`) — muestra porcentaje usado y cuenta atras hasta el reset, parseando timestamps ISO 8601 o Unix epoch
- Porcentaje de ventana de contexto desde `context_window.used_percentage`
- Rama git via `git symbolic-ref` (fallback a SHA corto en detached HEAD)

### Codigo de colores

| Uso      | Color    |
|----------|----------|
| 0–50%    | Verde    |
| 51–80%   | Amarillo |
| > 80%    | Rojo     |

Se aplica a rate limits y ventana de contexto.

## Instalacion

```bash
# 1. Copiar scripts
cp statusline-cockpit.sh ~/.claude/
cp statusline-legacy.sh ~/.claude/
chmod +x ~/.claude/statusline-cockpit.sh ~/.claude/statusline-legacy.sh

# 2. Añadir a ~/.claude/settings.json
# (fusionar con tu settings existente si ya tienes uno)
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-cockpit.sh"
  }
}
```

Reinicia Claude Code.

## Dependencias

| Herramienta | Se usa para                                | Requerida |
|-------------|--------------------------------------------|-----------|
| `jq`        | Parsear el JSON de entrada de Claude Code  | Si        |
| `git`       | Nombre de rama, conteo de archivos sucios  | Si        |
| `python3`   | Rate limits, contexto %, parseo de tiempos | Si        |
| `php`       | Version de PHP en deteccion de WordPress   | No        |
| `wp`        | Indicador de disponibilidad de wp-cli      | No        |
| `node`      | Version de Node.js en deteccion de stack   | No        |

## Estructura de archivos

```
~/.claude/
├── settings.json            # apunta statusLine al cockpit
├── statusline-cockpit.sh    # script principal — renderiza ambas lineas
└── statusline-legacy.sh     # linea 1 — modelo, limits, contexto, rama
```

## Licencia

MIT
