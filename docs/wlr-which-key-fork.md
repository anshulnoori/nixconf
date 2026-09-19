# wlr-which-key colors and breadcrumbs

Research date: 2026-09-19. Scope: source assessment only, not an implementation
or a tested UI. Recommendation: a small local patch against the pinned package,
not a separate fork repository. Existing Home Manager package and YAML support
suffice, according to the parent session's local inspection.

## Source baseline and existing work

- Pinned release: [v1.3.0, commit 6d66599](https://github.com/MaxVerevkin/wlr-which-key/commit/6d66599f0a7ff5f71b81fd402de1c3e6f390ac13), dated 2025-07-01.
- Upstream HEAD: [9fcf5ba](https://github.com/MaxVerevkin/wlr-which-key/commit/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b), dated 2025-11-21.
- The [release-to-HEAD comparison](https://github.com/MaxVerevkin/wlr-which-key/compare/v1.3.0...9fcf5bac31e39a2605752c97fb65125b2c9a3b3b)
  contains three changes: plain text instead of markup, configurable namespace,
  and safer error creation inside `pre_exec`. Menu code and Cargo files are unchanged.
  HEAD still declares version `1.3.0`, so the version string does not identify the source revision.
- The inspected [upstream PR list](https://github.com/MaxVerevkin/wlr-which-key/pulls?q=is%3Apr)
  contains no color-and-breadcrumb implementation. This is not a claim about every fork or unlisted branch.
- [Zach-Mac's color commit](https://github.com/Zach-Mac/wlr-which-key/commit/29b7fa4ca7f214ed418f72d8f6885a22f4ec93d5)
  adds `key_color` and `desc_color`, each falling back to `color`.
  It also adds row padding, but no group color, separator color, or breadcrumb.
  The inspected fork HEAD includes touch controls, external submenu files, and Cargo changes.
  Its small color pattern is useful precedent, not a drop-in solution.
- Other inspected comparisons included [theme-file support](https://github.com/MaxVerevkin/wlr-which-key/compare/master...damian-ds7:master)
  and a [TOML-based configuration redesign](https://github.com/MaxVerevkin/wlr-which-key/compare/master...clarajk:master).
  Neither justifies adopting a larger fork for this request.

## Small patch boundary

The relevant owners are:

| Source                                                                                                                                                                      | Existing behavior and proposed change                                                                                                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`src/config.rs`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/src/config.rs), `Config`                                       | One global `color`. Add four optional colors and one boolean.                                                                                       |
| [`src/config/compat.rs`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/src/config/compat.rs), `From<Config>`                   | Explicit legacy conversion. Initialize new fields to `None`/`false`.                                                                                |
| [`src/menu.rs`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/src/menu.rs), `Menu::push_page`                                  | Builds all pages recursively, stores parent indices, and prefixes submenu descriptions with `+`. Precompute an optional breadcrumb layout per page. |
| Same file, `render_column`                                                                                                                                                  | Already renders keys, separators, and descriptions separately. Select their colors here, with submenu descriptions identified by `Action::Submenu`. |
| Same file, `width`, `height`, `render`                                                                                                                                      | Include breadcrumb width and height, then offset all columns below the header.                                                                      |
| [`src/text.rs`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/src/text.rs), `ComputedText::{new, render}`                      | Owns Pango layouts and measured dimensions. `RenderOptions::fg_color` already supplies per-layout color.                                            |
| [`src/main.rs`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/src/main.rs), `State::handle_action`, `draw`, `layer_surface_cb` | Owns navigation redraw, surface dimensions, frame throttling, and configure acknowledgement.                                                        |

Proposed modern YAML additions, with the locally observed NVF palette:

```yaml
key_color: "#83a598"
desc_color: "#fb4934"
group_color: "#d3869b"
separator_color: "#665c54"
show_breadcrumbs: true
```

Each omitted color falls back directly to existing `color`. The boolean defaults
to `false`. Existing `background`, `border`, `font`, and `separator` remain unchanged.
No entry schema change or arbitrary markup is necessary. Legacy configuration
continues to work, but new fields require the modern list-based format.
Both parsers reject unknown fields, so patched YAML will fail on an unpatched binary.

The proposed breadcrumb reads `+Window » +Resize`, using ancestor descriptions
without modifying the stored descriptions. It excludes the root, which has no
existing label. An empty description can fall back to the configured key label.
The whole header uses the resolved key color, which matches the observed
`WhichKeyTitle`. A separate breadcrumb color is unnecessary for this palette.

The [which-key.nvim Helix preset](https://github.com/folke/which-key.nvim/blob/3aab2147e74890957785941f0c1ad87d0a44c15a/lua/which-key/presets.lua)
uses a bottom-right rounded window and a left-aligned border title.
Its [`view.trail`](https://github.com/folke/which-key.nvim/blob/3aab2147e74890957785941f0c1ad87d0a44c15a/lua/which-key/view.lua)
walks ancestors and uses `WhichKeyTitle` for the entire border trail.
An interior header is a deliberate small-patch approximation, not an exact border-title replica.
Existing anchor, corner, padding, and border controls cover much of the remaining appearance.
Terminal cell sizing and Pango sizing differ, so the same font size does not guarantee identical dimensions.

Parent-session observations, not independently measured here: `WhichKeyNormal`
background is `#1d2021`. `WhichKeyBorder` is `#d5c4a1` on `#1d2021`.
Kitty uses JetBrainsMono Nerd Font at size 9. No Neovim integration or NVF edit is required.

## Compatibility and navigation risks

**v1.3.0 uses `set_markup`, not `set_text`.** Upstream
[PR #27](https://github.com/MaxVerevkin/wlr-which-key/pull/27) fixes literal `<`
and removes undocumented markup support. A v1.3.0 patch needs this plain-text
change as a separate prerequisite. Existing markup descriptions will become literal text.
This is the intentional compatibility exception to otherwise unchanged defaults.
The menu patch applies to the same menu implementation at HEAD, but config
conversion must preserve HEAD's additional `namespace` field.

Breadcrumb state must follow the page tree, not a stack of pressed keys.
`get_action` maps Backspace to the parent page, while `navigate_to_key_sequence`
uses `set_page` for `--initial-keys`. A page-owned, precomputed layout handles
both paths, sibling navigation, aliases, and `keep_open` without synchronization.
The layout owns its text, so it must not borrow temporary ancestor strings.
Numeric parent indices survive recursive growth of `pages`. References into
that vector cannot remain live across recursive pushes.

The proposed geometry uses the larger of column width and breadcrumb width.
Header height plus one existing padding gap precedes the columns.
Root and disabled states reserve no header space. Long trails can exceed the
output width, as existing long descriptions can. That limitation needs an
explicit compositor test, not a claim of automatic wrapping or ellipsis.

**Redraw is a prerequisite for reliable breadcrumbs.**
[PR #43](https://github.com/MaxVerevkin/wlr-which-key/pull/43), inspected at
[1c7ee0b](https://github.com/ivandimitrov8080/wlr-which-key/commit/1c7ee0bc75d06f0f81389a9dc5397c0cc0ce192f),
adds `self.draw(conn)` after the entire action match. It remains open.
Reports [#34](https://github.com/MaxVerevkin/wlr-which-key/issues/34) and
[#41](https://github.com/MaxVerevkin/wlr-which-key/issues/41) describe active but stale submenus.
Source inspection shows that submenu navigation requests a size and commits,
but does not directly draw. It relies on a subsequent configure event.
Equal-sized pages therefore need an explicit redraw path even if their breadcrumb widths match.

The PR is evidence of the fix direction, not runtime verification.
A focused adaptation can request redraw only for submenu transitions.
It must preserve `draw`'s frame throttling and configure acknowledgement.
Changed-size transitions also need tests: drawing before a new configure can
temporarily use requested rather than compositor-selected dimensions.
No new buffer ownership or event-loop mechanism is necessary.

## Tests, build impact, and estimate

The implementation needs these checks:

- Configuration tests: unchanged old and modern fixtures, omitted-color fallback,
  each distinct color, and breadcrumb default-off behavior.
- Text tests: literal `<`, `&`, Unicode, and markup-like descriptions.
  All color roles need distinct values, including command versus submenu descriptions.
- Navigation tests: root, two nested levels, Backspace, siblings, key aliases,
  `--initial-keys`, and a harmless `keep_open` command.
- Geometry tests: header wider than columns and narrower than columns,
  multicolumn menus, root return, and long paths.
- Compositor tests: equal-sized and changed-sized page transitions, rapid navigation,
  integer scaling, and inspected screenshots of root and nested states.

The [upstream CI](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/.github/workflows/rust.yml)
runs Cargo check, tests, formatting, and Clippy. Those checks alone do not
establish correct Wayland redraw behavior.

[`Cargo.toml`](https://github.com/MaxVerevkin/wlr-which-key/blob/9fcf5bac31e39a2605752c97fb65125b2c9a3b3b/Cargo.toml)
declares Rust edition 2024 and GPL-3.0-only. Existing Pango/Cairo APIs suffice,
with no proposed Cargo dependency or lockfile changes. The parent reports existing
native dependencies on Cairo, GLib, libxkbcommon, and Pango.
A source-only Nix patch requires a package rebuild but normally preserves the
existing vendored-dependency `cargoHash`. Parent verification covers the exact packaging.

The local baseline uses `v1.3.0.tar.gz` and
`cargoHash = "sha256-v+4/lD00rjJvrQ2NQqFusZc0zQbM9mBG5T9bNioNGKQ="`.
The repository already has a Waybar `overrideAttrs` patch pattern, according to
the parent session. The same approach limits maintenance to patch rebases and tests.
Distribution of a modified binary must satisfy GPL-3.0-only obligations,
including license notices and corresponding source. Private exploration requires no public fork.

Estimated effort: **1–2 developer days** for a reviewed local patch and tests,
assuming a working Rust/Nix build and access to the target compositor.
Colors take roughly 1–2 hours. Breadcrumb layout takes 3–5 hours.
Compatibility, redraw, tests, and packaging checks take 4–8 hours.
Exact border-title drawing, automatic path truncation, and compositor-specific
failures exceed this estimate. Recommendation: retain the local package pin,
carry the small patch first, and consider upstream submission or publication only later.

No production configuration changed. No implementation, build, or compositor test
ran during this research. The estimate and proposed behavior are engineering judgments,
not measured implementation results.
