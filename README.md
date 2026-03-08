# GitFlow CLI

A modern CLI tool for streamlining Git workflows.

## Installation

```bash
git clone https://github.com/philipdaquin/GitFlow.git
cd GitFlow
swift build -c release
```

## Usage

```bash
# Run the CLI
swift run GitFlow --help

# Or after building
./build/release/GitFlow --help
```

## Commands

| Command | Description |
|---------|-------------|
| `commit` | Quick commit with auto messages |
| `branch` | Branch management |
| `changelog` | Generate changelog |
| `undo` | Undo commits |
| `stash` | Stash helpers |
| `sync` | Sync with remote |
| `info` | Repository info |
| `config` | Configuration |

## Example

```bash
gitflow commit -m "feat: add new feature"
gitflow branch list
gitflow changelog --from v1.0.0
```

## Tech Stack

- Swift
- Foundation

## License

MIT
