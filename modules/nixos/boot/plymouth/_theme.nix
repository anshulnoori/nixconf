{
  config,
  inputs,
  lib,
  pkgs,
}: let
  colors = config.lib.stylix.colors;
  themeName = "hyprlock-luks";
  font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
  source = "${inputs.omarchy-rice}/themes/flexoki-light/backgrounds/1-orb.png";
  wallpaper = pkgs.runCommand "flexoki-orb-gruvbox.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
    magick ${source} -colorspace gray -negate \
      +level-colors '#${colors.base00}','#${colors.base05}' "$out"
  '';
  hyprlockBlur =
    (import "${inputs.monorepo}/nix/artifacts/hyprlock-blur.nix").${pkgs.stdenv.hostPlatform.system} {inherit pkgs;};
  prepareBackground = pkgs.writeShellApplication {
    name = "nixconf-prepare-boot-background";
    runtimeInputs = with pkgs; [
      coreutils
      hyprlockBlur
    ];
    text = ''
      theme=/etc/plymouth/themes/${themeName}
      runtime=/run/nixconf-boot
      temporary="$runtime/background.png.new"

      install -d -m 0755 "$runtime"
      cp "$theme"/*.png "$runtime/"

      if hyprlock-blur \
        --shaders ${pkgs.hyprlock.src}/src/renderer/Shaders.hpp \
        ${lib.escapeShellArg (toString wallpaper)} \
        "$temporary"; then
        mv -f "$temporary" "$runtime/background.png"
      else
        rm -f "$temporary"
        echo "Using the pre-rendered Plymouth background" >&2
      fi
    '';
  };
  script = import ./_script.nix {inherit colors lib;};
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
      progress_width=$((300 * scale))
      progress_height=$((10 * scale))

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

      magick \
        -size "''${progress_width}x''${progress_height}" \
        "xc:#${colors.base02}" \
        "$themeDir/progress-track-''${scale}x.png"

      magick \
        -size "''${progress_width}x''${progress_height}" \
        "xc:#${colors.base05}" \
        "$themeDir/progress-fill-''${scale}x.png"
    done

    cat > "$themeDir/${themeName}.plymouth" <<EOF
    [Plymouth Theme]
    Name=Hyprlock LUKS
    Description=Hyprlock-matched encrypted-volume prompt
    ModuleName=script

    [script]
    ImageDir=/run/nixconf-boot
    ScriptFile=/etc/plymouth/themes/${themeName}/${themeName}.script
    EOF

    cat > "$themeDir/${themeName}.script" <<'EOF'
    ${script}
    EOF
  '';
in {
  inherit
    font
    hyprlockBlur
    prepareBackground
    theme
    themeName
    wallpaper
    ;
}
