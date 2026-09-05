{inputs, ...}: {
  flake.modules.nixos.base.system = {
    stateVersion = "26.05";
    configurationRevision =
      inputs.self.rev
      or inputs.self.dirtyRev
      or "dirty";
  };
}
