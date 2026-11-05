# Roblox Luau Framework

Two small, independent Luau utilities for Roblox developers.

This is a small toolkit, not a complete game framework. Both modules were newly written with AI assistance. The repository contains no game assets, gameplay systems, or private game configuration. No adoption, download, contributor, or performance metrics are claimed.

## Modules

| Module | Purpose | Runtime dependencies |
| --- | --- | --- |
| `FixedWindowLimiter` | Limit calls within a fixed time window for one stream | Luau standard library |
| `EscapeRichText` | Encode five special characters in plain text for Roblox RichText | Luau standard library |

## Using the modules in Roblox Studio

After reviewing the source, place each file in a ModuleScript with the matching name in a separate test place. The examples below assume the modules are siblings of the calling script. No game assets, place IDs, configuration files, or external packages are needed.

```luau
local FixedWindowLimiter = require(script.Parent.FixedWindowLimiter)
local allow = FixedWindowLimiter.new(3, 2)

-- Reuse this closure for the same stream. Time is in seconds.
if allow(os.clock()) then
    print("Allowed")
end
```

`new(maxCalls, windowSeconds)` returns a function `allow(now) -> boolean`.

- `maxCalls` must be a positive integer at most 9007199254740991; the window must be positive and finite.
- Each limiter has independent state. Its first call starts its window. The first call at or after the window boundary starts a new window.
- Supply finite, nonnegative, nondecreasing timestamps in seconds. Invalid values raise an error before changing state.
- Denied calls do not consume additional quota. Idle time does not accumulate credit.
- A fixed window permits bursts across its boundary; it is not a rolling-window or token-bucket algorithm.
- For network handlers, keep both the closure and clock on the server. Use one closure per intended stream, keep it across calls, and release player-owned references when that player leaves. Authorization and argument validation remain the caller's responsibility. There is no shared state across servers.

```luau
local escape = require(script.Parent.EscapeRichText)
local plainText = '<b>Hello & "welcome"</b>'
local encoded = escape(plainText)
-- &lt;b&gt;Hello &amp; &quot;welcome&quot;&lt;/b&gt;
```

`escape(text)` accepts a string and returns exactly one string. It escapes `&`, `<`, `>`, double quotes and apostrophes using the [Roblox documented escape forms](https://create.roblox.com/docs/ui/rich-text#escape-forms). Insert the result in a RichText text node. Escape each plain-text input once; already encoded text will be encoded again. This does not perform content moderation or handle HTML, URLs, scripts or arbitrary attribute contexts.

## Local checks

Development tool versions are recorded in `rokit.toml`: Lune 0.11.1, Selene 0.32.0 and StyLua 2.6.0. Tool installation is separate; the modules have no package dependencies. With those tools available, run from this directory:

```text
lune run tests/run.luau
selene src tests
stylua --check --syntax Luau src tests
```

The 12 test cases cover quotas, time boundaries, independent state, idle gaps, invalid inputs, boundary bursts, all five escapes, literal markup, repeated escaping, Unicode, empty strings and return arity. The test runner uses Lune relative imports; it is not a Roblox Studio Script.

Before using the modules in a live game, manually check them in a fresh Studio place. For RichText, render a label containing the encoded example and verify the tag characters are visible. For the limiter, check the same quota sequence from a server Script. The 12 local tests pass with the versions above. Roblox Studio integration, multiplayer behavior and a full static Luau typecheck have not been verified.

## License and provenance

[MIT License](LICENSE), copyright (c) 2026 Mikirik909. The modules, tests and documentation were newly written for this toolkit. No third-party runtime package or game asset is bundled. Development tools retain their own licenses.
