_: {
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors;
    application = pkgs.stdenv.mkDerivation {
      pname = "nixconf-boot-splash";
      version = "1.0.0";
      dontUnpack = true;
      nativeBuildInputs = [pkgs.pkg-config];
      buildInputs = [
        pkgs.gtk4
        pkgs.gtk4-layer-shell
      ];
      buildPhase = ''
        cat > boot-splash.c <<'EOF'
        #include <gtk/gtk.h>
        #include <gtk4-layer-shell.h>
        #include <glib-unix.h>

        static const char *background;
        static GtkApplication *application;

        static gboolean
        quit_splash(gpointer unused)
        {
          (void)unused;
          g_application_quit(G_APPLICATION(application));
          return G_SOURCE_REMOVE;
        }

        static void
        make_input_transparent(GtkWidget *widget, gpointer unused)
        {
          cairo_region_t *empty = cairo_region_create();
          (void)unused;
          gdk_surface_set_input_region(gtk_native_get_surface(GTK_NATIVE(widget)), empty);
          cairo_region_destroy(empty);
        }

        static gboolean
        advance_progress(gpointer data)
        {
          GtkProgressBar *progress = GTK_PROGRESS_BAR(data);
          double fraction = gtk_progress_bar_get_fraction(progress);

          if (fraction < 0.90)
            gtk_progress_bar_set_fraction(progress, fraction + 0.01);
          return G_SOURCE_CONTINUE;
        }

        static void
        add_monitor(GdkMonitor *monitor)
        {
          GtkWindow *window = GTK_WINDOW(gtk_application_window_new(application));
          GtkWidget *overlay = gtk_overlay_new();
          GtkWidget *picture = gtk_picture_new_for_filename(background);
          GtkWidget *progress = gtk_progress_bar_new();

          gtk_window_set_decorated(window, FALSE);
          gtk_widget_set_focusable(GTK_WIDGET(window), FALSE);
          gtk_layer_init_for_window(window);
          gtk_layer_set_namespace(window, "nixconf-boot-splash");
          gtk_layer_set_layer(window, GTK_LAYER_SHELL_LAYER_OVERLAY);
          gtk_layer_set_monitor(window, monitor);
          gtk_layer_set_keyboard_mode(window, GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);
          gtk_layer_set_exclusive_zone(window, 0);
          for (int edge = GTK_LAYER_SHELL_EDGE_LEFT;
               edge <= GTK_LAYER_SHELL_EDGE_BOTTOM; edge++)
            gtk_layer_set_anchor(window, edge, TRUE);

          gtk_picture_set_content_fit(GTK_PICTURE(picture), GTK_CONTENT_FIT_COVER);
          gtk_widget_set_hexpand(picture, TRUE);
          gtk_widget_set_vexpand(picture, TRUE);
          gtk_overlay_set_child(GTK_OVERLAY(overlay), picture);

          gtk_widget_set_size_request(progress, 300, 10);
          gtk_widget_set_halign(progress, GTK_ALIGN_CENTER);
          gtk_widget_set_valign(progress, GTK_ALIGN_CENTER);
          gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(progress), 0.01);
          gtk_overlay_add_overlay(GTK_OVERLAY(overlay), progress);
          gtk_window_set_child(window, overlay);

          g_signal_connect(window, "map", G_CALLBACK(make_input_transparent), NULL);
          g_timeout_add(140, advance_progress, progress);
          gtk_window_present(window);
        }

        static void
        activate(GtkApplication *app, gpointer unused)
        {
          GListModel *monitors = gdk_display_get_monitors(gdk_display_get_default());
          GtkCssProvider *css = gtk_css_provider_new();
          const char *stylesheet =
            "progressbar trough {"
            "  min-width: 300px; min-height: 10px;"
            "  background: #${colors.base02}; border-radius: 0;"
            "}"
            "progressbar progress {"
            "  min-height: 10px;"
            "  background: #${colors.base05}; border-radius: 0;"
            "}";
          (void)app;
          (void)unused;

          gtk_css_provider_load_from_string(css, stylesheet);
          gtk_style_context_add_provider_for_display(
            gdk_display_get_default(), GTK_STYLE_PROVIDER(css),
            GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
          g_object_unref(css);

          for (guint i = 0; i < g_list_model_get_n_items(monitors); i++) {
            GdkMonitor *monitor = g_list_model_get_item(monitors, i);
            add_monitor(monitor);
            g_object_unref(monitor);
          }
        }

        int
        main(int argc, char **argv)
        {
          if (argc != 2)
            return 2;

          background = argv[1];
          application = gtk_application_new("org.nixconf.BootSplash",
                                             G_APPLICATION_NON_UNIQUE);
          g_signal_connect(application, "activate", G_CALLBACK(activate), NULL);
          g_unix_signal_add(SIGTERM, quit_splash, NULL);
          g_unix_signal_add(SIGINT, quit_splash, NULL);
          int status = g_application_run(G_APPLICATION(application), 1, argv);
          g_object_unref(application);
          return status;
        }
        EOF

        $CC $(pkg-config --cflags gtk4 gtk4-layer-shell-0) \
          -Wall -Wextra -Werror -O2 boot-splash.c -o nixconf-boot-splash \
          $(pkg-config --libs gtk4 gtk4-layer-shell-0)
      '';
      installPhase = ''
        install -Dm755 nixconf-boot-splash "$out/bin/nixconf-boot-splash"
      '';
    };
    launcher = pkgs.writeShellApplication {
      name = "nixconf-boot-splash-run";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.systemd
      ];
      text = ''
        background=/run/nixconf-boot/background.png
        if [[ ! -r "$background" ]]; then
          background=${lib.escapeShellArg (toString config.nixconf.desktop.wallpaper)}
        fi

        splash_pid=
        cleanup() {
          if [[ -n "$splash_pid" ]] && kill -0 "$splash_pid" 2>/dev/null; then
            kill "$splash_pid" 2>/dev/null || true
            wait "$splash_pid" 2>/dev/null || true
          fi
        }
        trap cleanup EXIT INT TERM

        # Hyprland normally exports a live socket before emitting its start event.
        # Retrying here also covers unusually slow Wayland socket creation.
        for _ in {1..40}; do
          if [[ -n "''${WAYLAND_DISPLAY:-}" \
            && -S "''${XDG_RUNTIME_DIR:-/run/user/$UID}/$WAYLAND_DISPLAY" ]]; then
            break
          fi
          sleep 0.05
        done

        ${lib.getExe' application "nixconf-boot-splash"} "$background" 2>/dev/null &
        splash_pid=$!

        for _ in {1..100}; do
          if systemctl --user is-active --quiet swaybg.service \
            && systemctl --user is-active --quiet waybar.service; then
            sleep 0.25
            break
          fi
          kill -0 "$splash_pid" 2>/dev/null || exit 0
          sleep 0.25
        done
      '';
    };
  in {
    home.packages = [launcher];

    wayland.windowManager.hyprland.extraConfig = ''
      hl.layer_rule({
        match = { namespace = "nixconf-boot-splash" },
        no_anim = true,
        animation = "none",
      })

      hl.on("hyprland.start", function()
        hl.exec_cmd("${lib.getExe launcher}")
      end)
    '';
  };
}
