{inputs, ...}: {
  flake.modules.nixos.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    themeName = "hyprlock-luks";
    font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
    source = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
    wallpaper = pkgs.runCommand "flexoki-orb-gruvbox.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
      magick ${source} -colorspace gray -negate \
        +level-colors '#${colors.base00}','#${colors.base05}' "$out"
    '';
    toPlymouthColor = color:
      lib.concatMapStringsSep ", " (
        offset:
          toString (
            (lib.fromHexString (builtins.substring offset 2 color)) / 255.0
          )
      ) [0 2 4];
    theme = pkgs.runCommand "${themeName}-plymouth-theme" {nativeBuildInputs = [pkgs.imagemagick];} ''
      themeDir="$out/share/plymouth/themes/${themeName}"
      mkdir -p "$themeDir"

      magick ${wallpaper} \
        -resize '3840x2160^' \
        -gravity center \
        -extent 3840x2160 \
        -blur 0x16 \
        -strip \
        "$themeDir/background.png"

      for scale in 1 2; do
        width=$((400 * scale))
        height=$((60 * scale))
        inset=$((2 * scale))
        far_x=$((width - 3 * scale))
        far_y=$((height - 3 * scale))
        point_size=$((16 * scale))
        bullet_size=$((16 * scale))
        bullet_center=$((8 * scale))
        bullet_edge=$scale

        magick \
          -size "''${width}x''${height}" xc:none \
          -fill '#${colors.base00}cc' \
          -stroke '#${colors.base05}' \
          -strokewidth $((4 * scale)) \
          -draw "rectangle ''${inset},''${inset} ''${far_x},''${far_y}" \
          "$themeDir/entry-''${scale}x.png"

        magick \
          "$themeDir/entry-''${scale}x.png" \
          -font ${font} \
          -pointsize "$point_size" \
          -fill '#${colors.base05}' \
          -gravity center \
          -annotate +0+0 'Enter Password' \
          "$themeDir/entry-empty-''${scale}x.png"

        magick \
          -size "''${bullet_size}x''${bullet_size}" xc:none \
          -fill '#${colors.base05}' \
          -draw "circle ''${bullet_center},''${bullet_center} ''${bullet_center},''${bullet_edge}" \
          "$themeDir/bullet-''${scale}x.png"
      done

      cat > "$themeDir/${themeName}.plymouth" <<EOF
      [Plymouth Theme]
      Name=Hyprlock LUKS
      Description=Hyprlock-matched encrypted-volume prompt
      ModuleName=script

      [script]
      ImageDir=$themeDir
      ScriptFile=/etc/plymouth/themes/${themeName}/${themeName}.script
      EOF

      cat > "$themeDir/${themeName}.script" <<'EOF'
      Window.SetBackgroundTopColor(${toPlymouthColor colors.base00});
      Window.SetBackgroundBottomColor(${toPlymouthColor colors.base00});

      screen.x = Window.GetX(0);
      screen.y = Window.GetY(0);
      screen.w = Window.GetWidth(0);
      screen.h = Window.GetHeight(0);
      center.x = screen.x + screen.w / 2;
      center.y = screen.y + screen.h / 2;
      scale = 1;
      if (screen.w >= 2560)
          scale = 2;
      if (screen.h >= 1600)
          scale = 2;

      background.source = Image("background.png");
      background.image = background.source.Scale(screen.w, screen.h);
      background.sprite = Sprite(background.image);
      background.sprite.SetPosition(screen.x, screen.y, -100);

      entry.image = Image("entry-" + scale + "x.png");
      entry.empty_image = Image("entry-empty-" + scale + "x.png");
      entry.sprite = Sprite(entry.image);
      entry.x = center.x - entry.image.GetWidth() / 2;
      entry.y = center.y - entry.image.GetHeight() / 2;
      entry.sprite.SetPosition(entry.x, entry.y, 100);
      entry.sprite.SetOpacity(0);

      bullet.image = Image("bullet-" + scale + "x.png");
      bullet.sprites = [];
      status.sprite = Sprite();

      fun hide_bullets()
      {
          for (i = 0; bullet.sprites[i]; i++)
              bullet.sprites[i].SetOpacity(0);
      }

      fun display_password(prompt, bullet_count)
      {
          status.sprite.SetOpacity(0);
          entry.sprite.SetOpacity(1);
          hide_bullets();

          if (bullet_count == 0)
              entry.sprite.SetImage(entry.empty_image);
          else
              entry.sprite.SetImage(entry.image);

          visible = bullet_count;
          if (visible > 19)
              visible = 19;

          dot_spacing = 3 * scale;
          spacing = bullet.image.GetWidth() + dot_spacing;
          start_x = center.x - (visible * spacing - dot_spacing) / 2;
          bullet_y = center.y - bullet.image.GetHeight() / 2;

          for (i = 0; i < visible; i++)
          {
              if (!bullet.sprites[i])
                  bullet.sprites[i] = Sprite(bullet.image);

              bullet.sprites[i].SetPosition(start_x + i * spacing, bullet_y, 101);
              bullet.sprites[i].SetOpacity(1);
          }
      }

      fun display_question(prompt, entry_text)
      {
          hide_bullets();
          entry.sprite.SetImage(entry.image);
          entry.sprite.SetOpacity(1);

          question.image = Image.Text(entry_text, ${toPlymouthColor colors.base05}, 1, "JetBrainsMono Nerd Font " + 16 * scale);
          status.sprite.SetImage(question.image);
          status.sprite.SetPosition(center.x - question.image.GetWidth() / 2, center.y - question.image.GetHeight() / 2, 101);
          status.sprite.SetOpacity(1);
      }

      fun display_message(message)
      {
          status.image = Image.Text(message, ${toPlymouthColor colors.base08}, 1, "JetBrainsMono Nerd Font " + 14 * scale);
          status.sprite.SetImage(status.image);
          status.sprite.SetPosition(center.x - status.image.GetWidth() / 2, entry.y + entry.image.GetHeight() + 18 * scale, 101);
          status.sprite.SetOpacity(1);
      }

      fun display_normal()
      {
          entry.sprite.SetOpacity(0);
          status.sprite.SetOpacity(0);
          hide_bullets();
      }

      Plymouth.SetDisplayPasswordFunction(display_password);
      Plymouth.SetDisplayQuestionFunction(display_question);
      Plymouth.SetMessageFunction(display_message);
      Plymouth.SetDisplayNormalFunction(display_normal);
      EOF
    '';
  in {
    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "systemd.show_status=false"
        "rd.systemd.show_status=false"
        "udev.log_level=0"
        "rd.udev.log_level=0"
        "vt.global_cursor_default=0"
      ];
      plymouth = {
        enable = true;
        showDelay = 0;
        inherit font;
        theme = themeName;
        themePackages = [theme];
      };
    };
  };
}
