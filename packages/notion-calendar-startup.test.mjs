import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const source = readFileSync(process.argv[2], "utf8");
function extract(start, end) {
  assert.equal(source.split(start).length, 2, `Unique anchor: ${start}`);
  return source.slice(source.indexOf(start), source.indexOf(end, source.indexOf(start)));
}
const callbacks = [
  extract("function Vt(){", "function Ht(){"),
  extract("function Yt(){", "function Xt(){"),
  extract("function on(){", "function sn("),
].join("\n");
const secondInstance = source.match(/f\.default\.app\.on\(`second-instance`,.*?}\)/)?.[0];
assert.ok(secondInstance, "Second-instance handler exists");

for (const login of [true, false]) {
  let visible = false;
  let shows = 0;
  let activate;
  const context = vm.createContext({
    process: { platform: "linux", argv: login ? ["app", "--from-login"] : ["app"] },
    L: false, R: false, Rt: false, H: false, F: undefined, zt: undefined, Bt: [],
    Ot: "--soft-quit-relaunch",
    rn: () => ({ openAsHidden: false }),
    an: () => login,
    $: () => {},
    f: { default: { app: { on: (_event, handler) => { activate = handler; } } } },
    Zt: () => {},
    P: {
      isVisible: () => visible,
      show: () => { visible = true; shows++; },
      hide: () => { visible = false; },
      webContents: { send: () => {} },
    },
  });
  vm.runInContext(callbacks, context);
  // Both the fallback timer and renderer's cronReady can invoke Vt.
  vm.runInContext("Vt(); Vt();", context);
  assert.equal(visible, !login, `login=${login}: initial visibility`);
  assert.equal(shows, login ? 0 : 1, `login=${login}: no startup flash`);
  vm.runInContext("function Lt(){Yt()}\n" + secondInstance, context);
  activate({}, ["app", "--from-login"]);
  assert.equal(visible, !login, "Duplicate autostart must not raise the window");
  activate({}, ["app"]);
  assert.equal(visible, true, "Manual activation shows the window");
  assert.equal(context.H, false, "Manual activation clears background state");
}
console.log("PASS: login stays hidden across readiness callbacks; manual launch and activation show");
