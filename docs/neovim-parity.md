# Neovim parity with the Mac reference

## Scope and reference

This comparison used the live Mac configuration on September 5, 2026.
The checkout first received a fast-forward from `origin/master`.
The editor remains nvf-managed under `modules/home/shell/neovim/`.
No LazyVim runtime dependency, host activation, or plugin update forms part of this change.

The reference executable was `/opt/homebrew/bin/nvim`, version 0.12.5.
Its configuration directory was `~/.config/nvim`, without an `NVIM_APPNAME` or XDG override.
The entrypoint imports `config.lazy`, which imports LazyVim and the local plugin modules.
Both `lazy-lock.json` and `lazyvim.json` contributed to the inventory.
The custom keymap and autocmd files were empty, so installed LazyVim modules supplied most interactions.
Adapted components retain attribution to LazyVim and its Apache-2.0 license in `modules/home/shell/neovim/LICENSE.LazyVim`.
The unimported `config/biome.lua` and socket-cleanup files did not define effective reference behavior.

The comparison used copies of the configuration and installed plugins in isolated XDG directories.
Automatic installs, update checks, Amp, and Copilot were disabled in this reference copy.
The original configuration and existing editor sessions remained unchanged.
Only public fixture text appeared in the screenshots.

## Parity inventory

`<leader>` is Space. `<localleader>` is backslash.
The inventory covers normal, insert, visual, operator-pending, select, terminal, and command-line modes.
Plugin-local maps and LSP maps also depend on loaded buffers and attached servers.
Raw map counts are therefore not a measure of parity.

| Area                   | Reference contract and implemented behavior                                                                                                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Which-key              | `helix`, bottom-right placement, width 30–60 columns, height 4–75%, padding `{0,1}`, spacing 3, automatic `nxso` triggers, and plugin-aware delay. Buffer/window expansion, visual groups, local-map help, and window hydra are present. Linux retains the square which-key border. |
| Editor options         | Mapping timeout 300 ms, scroll context 4, two-space indentation, global statusline, conceal level 2, and completion height 10. Smooth scrolling, split placement, persistent undo, and wrapped-line movement also match. The nvf `tm` alias previously overrode `timeoutlen`.       |
| Basic maps             | Native split navigation/resizing, Alt-j/k movement, save across modes, visual indentation, search direction, clear highlights, buffer deletion/pinning/reordering, tabs, and quit. The buffer pin map no longer cycles buffers.                                                     |
| Pickers                | Space-Space and `ff` find files at the project root. `fF` uses cwd. `fg` finds Git files, not grep. `/`, `sg`, and `sG` search text. Histories, registers, diagnostics, symbols, TODOs, Git views, and visual-word searches have reference keys.                                    |
| Picker interactions    | Root selection considers LSP workspaces, the nearest `.git`/`lua` marker, then cwd. Alt-c changes root/cwd. Alt-t opens Trouble. Alt-s and normal-mode `s` use Flash labels.                                                                                                        |
| Explorer and terminal  | `e`/`fe` use the project root. `E`/`fE` use cwd. Terminal, Lazygit, scratch buffers, notification history, and notification dismissal retain their reference key families.                                                                                                          |
| Bufferline and Lualine | Single-buffer tabline hidden, no numerical buffer prefixes, pinning, buffer-safe deletion, diagnostics, and icon indicator. Global mode/branch/file/diagnostics/diff/progress/location/clock sections and Noice/DAP/profiler status are present.                                    |
| Noice and completion   | Top-centered command palette, bottom search, compact message routes, message history, signature scrolling, and rename preview. Blink uses Enter acceptance, Ctrl-y selection/acceptance, snippet Tab, automatic documentation after 200 ms, and command-line completion.            |
| Editing                | Yanky puts/history, Dial increments across reference filetypes, Flash selection, mini.ai text objects, mini.pairs guards, Markdown fences, comment insertion, and word-prefilled rename.                                                                                            |
| Diagnostics and Git    | Diagnostic icons, severity ordering, four-space virtual-text spacing, no insert-time updates, severity-specific jumps, Trouble maps, Gitsigns hunk maps, visual hunk actions, and staged/unstaged sign glyphs.                                                                      |
| Formatting             | `cf` formats manually. `uf` and `uF` control global and buffer format-on-save. Conform honors both switches and retains LSP fallback and project-provided formatter commands.                                                                                                       |
| Workflow               | `tr` runs the nearest test, `tt` the current file, and `tT` cwd. Test output/watch/debug, session restore/select/stop, DAP actions, `Gg`/`Gf`, and global UV maps match the reference key families.                                                                                 |
| Filetype behavior      | Text/Markdown wrapping and spelling, JSON without conceal, auxiliary-buffer `q`, last-position restoration, parent-directory creation, and LSP-local navigation/code actions. Existing VimTeX, render-markdown, and dotfile support remain.                                         |

The Minuet Blink map also needed correction.
`make_blink_map()` returns a list, but the previous configuration nested that list inside another list.
Blink rejected the nested value when completion loaded.
The change uses the returned function without changing token transport or automatic-request policy.

## Intentional Linux differences

- Stylix retains Gruvbox Dark Hard instead of the Mac's standard Gruvbox palette.
- The existing nvf square-border policy remains, with an explicit square which-key border.
  Noice and Snacks retain their own popup defaults.
- The terminal retains its documented JetBrains Mono Nerd Font configuration.
  Comparison screenshots used identical Kitty dimensions and font configuration, not a deployed Linux desktop.
- The dashboard says Neovim, not LazyVim.
  Lazy, LazyExtras, and update-count actions are absent because Nix owns plugins.
- `fc` and the dashboard configuration action use `/etc/nixos`.
- Native Neovim split navigation replaces tmux navigation because this setup uses zmx.
- No Mason, Copilot, Homebrew/JDK paths, obsolete socket cleanup, or global toolchains were imported.
- Per-project flakes own LSP integrations, test/debug adapters, and debugger configurations.
  These are project responsibilities, not missing global editor features.
  Project shells supply servers, formatters, linters, and build tools.
  Existing Biome/Tailwind diagnostic ownership remains unchanged.
- Amp and Minuet retain the documented Linux integration rather than the Mac's AI provider choices.

UV's global `x` prefix overlaps the diagnostics group in the reference.
This change preserves that interaction rather than silently choosing a different UV prefix.

## Lualine follow-up

Lualine now includes the conditional root badge, shortened relative path, filename highlights, readonly lock, and Trouble symbol breadcrumb.
The breadcrumb follows the cursor and respects `vim.b.trouble_lualine = false`.
Navigation and Lualine share the same root detector.

An isolated, in-process LSP fixture supplied nested symbols for the visual comparison.
The reference and target statusline text matched, including cursor-dependent breadcrumbs and the root/breadcrumb-hidden state.
Inspected screenshots also covered modified highlights and the readonly lock.
This fixture verifies the editor presentation, not a project language integration.

## Remaining differences and verification limits

- Injected-language formatting (`cF`) and LazyVim's plugin-spec search are not reproduced.
- The Linux nightly executable, compiled parser closure, Rust fuzzy backend, native tools, and authenticated integrations did not run on this Mac.

## Verification results

- nvf generated-Lua evaluation passed for `nixosConfigurations.t1`.
- The editor derivation evaluated as `x86_64-linux`.
- The editor build dry-run passed. It planned 69 builds and about 1 GiB of downloads.
  This result is not a successful package build.
- Building the Linux plugin-source derivations stopped at the architecture boundary.
  They require an `x86_64-linux` builder, but this runner provides `aarch64-darwin`.
- Native Darwin fetchers successfully obtained the pinned plugin sources for the runtime comparison.
  The generated target Lua ran under the Mac executable with those sources.
  The harness substituted Blink's Lua fuzzy backend and disabled Amp/Minuet network activity.
- `scripts/check-neovim-parity.lua` passed against that generated configuration.
  It checks effective options, maps, which-key geometry, format switches, completion, text objects, and filetype-specific Dial increments.
  Lualine checks cover root/cwd relationships, shortened paths, literal percent signs, modified/readonly files, unnamed buffers, and breadcrumb opt-out.
  Actual key input also verified nearest/file/cwd test dispatch without running external tests.
- Alejandra, Statix, Deadnix, Lua formatting, and `git diff --check` passed.
- The all-system flake check stopped at the unrelated private Notion Calendar input with `Permission denied (publickey)`.

Separate zmx sessions ran the reference and target at 120 columns × 40 lines.
Actual key input opened which-key, pickers, command completion, buffer pinning, and dashboards.
Inspected screenshots verified these layouts.
The target which-key content measured 34 columns × 29 rows in this fixture, not a full-width bottom window.
These captures validate the Mac runtime probe, not a deployed Linux generation.

Local evidence lives in `.amp/state/neovim-parity/` and is not part of the tracked configuration.
The thread links the inspected comparison images.

## Remaining target-device verification

On the Linux target, build the editor without activating a host generation:

```sh
nix build --no-link path:.#nixosConfigurations.t1.config.home-manager.users.mvs.programs.nvf.finalPackage
```

Use `path:.` while the new Lua files remain untracked.
The Git flake source omits untracked files.

In a disposable session with the built editor, run the regression script:

```vim
:luafile /path/to/nixconf/scripts/check-neovim-parity.lua
```

The script exits that session after completion.
It must not run in an editor with unsaved work.

Then verify these behaviors in representative project shells:

1. Compare which-key, file pickers, completion, and a pinned multi-buffer tabline at the same terminal dimensions.
2. Verify LSP attach, project diagnostics, formatter fallback, and native Treesitter text objects.
3. Verify Neotest adapters, DAP configurations, Gradle, UV, and VimTeX with project-provided tools.
4. Verify Amp startup and Minuet authentication separately, with authorized credentials.

No host generation was installed.
