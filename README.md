# openconstruct-zig

Zig binding for **OpenConstruct** — a thin client for structured agent onboarding.

## Why Zig?

Zig is a modern systems language ideal for ultralight deployments, WASM targets, and cross-compilation. This binding provides zero-dependency, comptime-friendly integration with the OpenConstruct onboarding flow.

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

### `OpenConstructClient`

The main client struct. Call `init()` to create, `deinit()` to clean up.

| Method | Description |
|---|---|
| `start()` | Begin a new onboarding session |
| `declareAgent(identity)` | Declare agent name, model, capabilities |
| `listModules(filter)` | List available modules, optionally filtered by domain |
| `selectModules(names)` | Select modules for the configuration |
| `chooseInterface(choice)` | Choose REST API, WebSocket, CLI, or SDK-embedded |
| `generateConfig()` | Produce the final `OnboardingConfig` |

### Types

- **`AgentIdentity`** — name, model, capabilities
- **`ModuleDescriptor`** — name, domain, version, description
- **`ModuleFilter`** — optional domain filter
- **`InterfaceChoice`** — enum: `rest_api`, `websocket`, `cli`, `sdk_embedded`
- **`OnboardingConfig`** — final structured output with session, agent, modules, interface, timestamp

## Building

```sh
zig build
```

## Testing

```sh
zig build test
```

## License

MIT
