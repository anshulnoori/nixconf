_: {
  flake.modules.nixos.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    themeName = "minimal-luks";
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

      magick \
        -size 420x64 "xc:#${colors.base01}" \
        -stroke "#${colors.base03}" -strokewidth 2 -fill none \
        -draw "rectangle 1,1 418,62" \
        "$themeDir/entry-base.png"

      magick \
        -size 28x32 xc:none \
        -stroke "#${colors.base05}" -strokewidth 3 -fill none \
        -draw "roundrectangle 7,2 21,22 7,7" \
        -stroke none -fill "#${colors.base05}" \
        -draw "rectangle 4,14 24,30" \
        "$themeDir/lock.png"

      magick \
        "$themeDir/entry-base.png" \
        "$themeDir/lock.png" -geometry +20+16 -composite \
        "$themeDir/entry.png"

      magick \
        -size 10x10 xc:none -fill "#${colors.base0A}" \
        -draw "circle 5,5 5,1" \
        "$themeDir/bullet.png"

      magick -size 320x4 "xc:#${colors.base02}" "$themeDir/progress-track.png"
      magick -size 320x4 "xc:#${colors.base0A}" "$themeDir/progress-fill.png"
      rm "$themeDir/entry-base.png" "$themeDir/lock.png"

      cat > "$themeDir/${themeName}.plymouth" <<EOF
      [Plymouth Theme]
      Name=Minimal LUKS
      Description=Unbranded password prompt and boot progress
      ModuleName=script

      [script]
      ImageDir=$themeDir
      ScriptFile=$themeDir/${themeName}.script
      EOF

      cat > "$themeDir/${themeName}.script" <<'EOF'
      Window.SetBackgroundTopColor(${toPlymouthColor colors.base00});
      Window.SetBackgroundBottomColor(${toPlymouthColor colors.base00});

      screen.x = Window.GetX(0);
      screen.y = Window.GetY(0);
      screen.w = Window.GetWidth(0);
      screen.h = Window.GetHeight(0);

      entry.image = Image("entry.png");
      entry.sprite = Sprite(entry.image);
      entry.x = screen.x + (screen.w - entry.image.GetWidth()) / 2;
      entry.y = screen.y + (screen.h - entry.image.GetHeight()) / 2;
      entry.sprite.SetPosition(entry.x, entry.y, 100);
      entry.sprite.SetOpacity(0);

      bullet.image = Image("bullet.png");
      password.active = 0;

      track.image = Image("progress-track.png");
      track.sprite = Sprite(track.image);
      track.x = screen.x + (screen.w - track.image.GetWidth()) / 2;
      track.y = screen.y + (screen.h - track.image.GetHeight()) / 2;
      track.sprite.SetPosition(track.x, track.y, 10);

      fill.source = Image("progress-fill.png");
      fill.sprite = Sprite();
      fill.sprite.SetPosition(track.x, track.y, 11);

      fun display_password(prompt, bullet_count)
      {
          password.active = 1;
          track.sprite.SetOpacity(0);
          fill.sprite.SetOpacity(0);
          entry.sprite.SetOpacity(1);

          for (i = 0; password_bullets[i]; i++)
              password_bullets[i].SetOpacity(0);

          visible = bullet_count;
          if (visible > 16)
              visible = 16;

          spacing = bullet.image.GetWidth() + 8;
          start_x = screen.x + screen.w / 2 - (visible * spacing - 8) / 2;
          bullet_y = entry.y + (entry.image.GetHeight() - bullet.image.GetHeight()) / 2;

          for (i = 0; i < visible; i++)
          {
              if (!password_bullets[i])
                  password_bullets[i] = Sprite(bullet.image);

              password_bullets[i].SetPosition(start_x + i * spacing, bullet_y, 101);
              password_bullets[i].SetOpacity(1);
          }
      }

      fun display_normal()
      {
          password.active = 0;
          entry.sprite.SetOpacity(0);
          for (i = 0; password_bullets[i]; i++)
              password_bullets[i].SetOpacity(0);
          track.sprite.SetOpacity(1);
      }

      fun boot_progress(duration, progress)
      {
          if (password.active)
          {
              fill.sprite.SetOpacity(0);
          }
          else
          {
              width = Math.Int(fill.source.GetWidth() * progress);
              if (width < 1)
              {
                  fill.sprite.SetOpacity(0);
              }
              else
              {
                  if (width > fill.source.GetWidth())
                      width = fill.source.GetWidth();

                  fill.image = fill.source.Scale(width, fill.source.GetHeight());
                  fill.sprite.SetImage(fill.image);
                  fill.sprite.SetOpacity(1);
              }
          }
      }

      Plymouth.SetDisplayPasswordFunction(display_password);
      Plymouth.SetDisplayNormalFunction(display_normal);
      Plymouth.SetBootProgressFunction(boot_progress);
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
        theme = themeName;
        themePackages = [theme];
      };
    };
  };
}
