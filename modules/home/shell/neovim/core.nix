{inputs, ...}: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    imports = [inputs.nvf.homeManagerModules.default];

    programs.nvf = {
      enable = true;
      defaultEditor = true;
      settings.vim = {
        package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
        viAlias = true;
        vimAlias = true;

        globals.mapleader = " ";
        options = {
          breakindent = true;
          cursorline = true;
          expandtab = true;
          ignorecase = true;
          mouse = "a";
          number = true;
          relativenumber = true;
          scrolloff = 8;
          shada = "!,'100,<50,s10,h";
          shiftwidth = 2;
          signcolumn = "yes";
          smartcase = true;
          splitbelow = true;
          splitright = true;
          tabstop = 2;
          termguicolors = true;
          timeoutlen = 300;
          undofile = true;
          updatetime = 200;
        };

        extraPackages = [
          pkgs.curl
          pkgs.ripgrep
        ];

        treesitter = {
          enable = true;
          context.enable = true;
        };
        git.gitsigns.enable = true;
        binds.whichKey.enable = true;
        notes.todo-comments.enable = true;
      };
    };
  };
}
