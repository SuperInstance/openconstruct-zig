# openconstruct-zig — Zero-Dependency Zig Binding

Zig client for [OpenConstruct](https://github.com/SuperInstance/OpenConstruct). Comptime-friendly, WASM-ready, cross-compilation out of the box.

## What This Gives You

- **Zero allocations in hot path** — comptime-known module lists
- **WASM target** — compile to `wasm32` for browser-based agents
- **Cross-compilation** — `zig build -Dtarget=aarch64-linux` just works
- **No dependencies** — pure Zig, links against nothing

## Quick Start

```zig
const oc = @import("openconstruct");

pub fn main() !void {
    var client = oc.OpenConstructClient.init();
    defer client.deinit();

    try client.start();

    const identity = oc.AgentIdentity{
        .name = "my-agent",
        .model = "glm-5.1",
        .capabilities = &.{"code_generation", "web_search"},
    };
    try client.declareAgent(identity);

    const modules = try client.listModules(.{ .domain = "math" });
    try client.selectModules(&.{"spectral-graph-core", "plato-room"});

    try client.chooseInterface(.websocket);
    const config = try client.generateConfig();
    _ = config;
}
```

## API

| Method | Description |
|--------|-------------|
| `init()` / `deinit()` | Create and destroy the client |
| `start()` | Begin a new onboarding session |
| `declareAgent(identity)` | Declare agent name, model, capabilities |
| `listModules(filter)` | List modules, optionally filtered by domain |
| `selectModules(names)` | Select modules for the configuration |
| `chooseInterface(choice)` | Choose: `rest_api`, `websocket`, `cli`, `sdk_embedded` |
| `generateConfig()` | Produce the final `OnboardingConfig` |

## Building

```bash
zig build
```

## License

MIT
