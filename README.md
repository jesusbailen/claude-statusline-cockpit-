# Claude Code Statusline Cockpit

Statusline personalizado de dos lineas para [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que te da visibilidad en tiempo real sobre tu sesion, proyecto y rate limits directamente en el terminal.

```
Claude Opus 4.6 | 5h: 12% (4h32m) | 7d: 3% (6d11h) | ctx: 8% | ⎇ main
✓ clean  │  WP 6.7 · PHP 8.2 · wp-cli ✓  │  mcp: 3  │  ~/myproject
```

## Que muestra

**Linea 1** — informacion de sesion:
- Modelo activo (ej. `Claude Opus 4.6`)
- Rate limits en ambas ventanas (`5h` y `7d`) con cuenta atras hasta el reset
- Uso de la ventana de contexto (`ctx`)
- Rama git actual

**Linea 2** — contexto del proyecto:
- Estado git: `✓ clean` o `✱N changes` con el numero de archivos modificados
- Stack detectado automaticamente: WordPress (con version, PHP y wp-cli), Laravel, Drupal, Joomla, Next.js, Node o Python
- Numero de servidores MCP conectados (del proyecto y globales)
- Directorio de trabajo

Todo con colores: verde (< 50%), amarillo (51-80%), rojo (> 80%).

## Instalacion paso a paso

### 1. Clonar el repositorio

```bash
git clone git@github.com:jesusbailen/claude-statusline-cockpit-.git
cd claude-statusline-cockpit-
```

### 2. Copiar los scripts a tu directorio de Claude Code

```bash
cp statusline-cockpit.sh ~/.claude/
cp statusline-legacy.sh ~/.claude/
```

### 3. Darles permisos de ejecucion

```bash
chmod +x ~/.claude/statusline-cockpit.sh ~/.claude/statusline-legacy.sh
```

### 4. Configurar Claude Code para usar el statusline

Abre tu archivo de configuracion:

```bash
nano ~/.claude/settings.json
```

Añade (o fusiona con tu configuracion existente) el bloque `statusLine`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-cockpit.sh"
  }
}
```

### 5. Reiniciar Claude Code

Cierra y vuelve a abrir Claude Code. El statusline aparecera automaticamente en la parte inferior del terminal.

## Requisitos

| Herramienta | Para que se usa                            | Obligatoria |
|-------------|--------------------------------------------|-------------|
| `jq`        | Parsear el JSON de entrada de Claude Code  | Si          |
| `git`       | Rama actual y conteo de archivos           | Si          |
| `python3`   | Rate limits, contexto y parseo de tiempos  | Si          |
| `php`       | Version de PHP en proyectos WordPress      | No          |
| `wp`        | Indicador de wp-cli disponible             | No          |
| `node`      | Version de Node.js en deteccion de stack   | No          |

## Estructura

```
~/.claude/
├── settings.json            # apunta statusLine al cockpit
├── statusline-cockpit.sh    # script principal — renderiza ambas lineas
└── statusline-legacy.sh     # linea 1 — modelo, limits, contexto, rama
```

## Licencia

MIT
