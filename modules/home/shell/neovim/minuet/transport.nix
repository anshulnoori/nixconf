{
  perSystem = {pkgs, ...}: let
    itemUuid = "dt3oxa4uin5steqpm6v266jrma";
    placeholder = "__MINUET_1PASSWORD_TOKEN__";
    mkPackage = runtimeInputs:
      (pkgs.writeShellApplication {
        name = "minuet-curl";
        inherit runtimeInputs;
        text = ''
          authorization_headers=0
          arguments=()

          while (($#)); do
            case "$1" in
              -H|--header)
                if (($# < 2)); then
                  echo "Minuet curl: $1 requires a value" >&2
                  exit 2
                fi
                header="$2"
                if [[ "''${header,,}" == authorization:* ]]; then
                  if [[ "$header" != "Authorization: Bearer ${placeholder}" ]]; then
                    echo 'Minuet curl: refusing an unexpected Authorization header' >&2
                    exit 2
                  fi
                  authorization_headers=$((authorization_headers + 1))
                else
                  arguments+=("$1" "$header")
                fi
                shift 2
                ;;
              --header=*)
                header="''${1#--header=}"
                if [[ "''${header,,}" == authorization:* ]]; then
                  if [[ "$header" != "Authorization: Bearer ${placeholder}" ]]; then
                    echo 'Minuet curl: refusing an unexpected Authorization header' >&2
                    exit 2
                  fi
                  authorization_headers=$((authorization_headers + 1))
                else
                  arguments+=("$1")
                fi
                shift
                ;;
              *)
                arguments+=("$1")
                shift
                ;;
            esac
          done

          if ((authorization_headers != 1)); then
            echo 'Minuet curl: expected exactly one placeholder Authorization header' >&2
            exit 2
          fi

          if ! token="$(op item get ${itemUuid} --fields label=credential --reveal)"; then
            echo 'Minuet curl: unlock 1Password to load the API token' >&2
            exit 1
          fi
          if [[ -z "$token" ]]; then
            echo 'Minuet curl: the 1Password credential field is empty' >&2
            exit 1
          fi
          if [[ ! "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]]; then
            echo 'Minuet curl: the API token contains unsupported characters' >&2
            exit 1
          fi

          exec curl \
            --config <(printf 'header = "Authorization: Bearer %s"\n' "$token") \
            "''${arguments[@]}"
        '';
      }).overrideAttrs (old: {
        passthru = (old.passthru or {}) // {inherit placeholder;};
      });
    package = mkPackage [
      pkgs._1password-cli
      pkgs.curl
    ];
    testToken = "test-minuet-token";
    mockOp = pkgs.writeShellApplication {
      name = "op";
      text = ''
        [[ "$#" == 6 ]]
        [[ "$1" == item ]]
        [[ "$2" == get ]]
        [[ "$3" == ${itemUuid} ]]
        [[ "$4" == --fields ]]
        [[ "$5" == label=credential ]]
        [[ "$6" == --reveal ]]
        printf %s ${testToken}
      '';
    };
    mockCurl = pkgs.writeShellApplication {
      name = "curl";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        [[ "$1" == --config ]]
        config="$2"
        shift 2

        [[ "$(cat "$config")" == \
          'header = "Authorization: Bearer ${testToken}"' ]]
        [[ "$(tr '\0' ' ' </proc/$$/cmdline)" != *${testToken}* ]]
        [[ "$(env)" != *${testToken}* ]]
        [[ "$1" == -L ]]
        [[ "$2" == -H ]]
        [[ "$3" == 'Content-Type: application/json' ]]
        [[ "$4" == -d ]]
        [[ "$5" == @/tmp/minuet-request ]]
        [[ "$6" == https://example.test/v1/chat/completions ]]
        [[ "$#" == 6 ]]
        printf response
      '';
    };
    testWrapper = mkPackage [
      mockCurl
      mockOp
    ];
  in {
    packages.minuet-curl = package;

    checks.minuet-credential-transport = pkgs.runCommand "minuet-credential-transport" {} ''
      output="$(${testWrapper}/bin/minuet-curl \
        -H 'Authorization: Bearer ${placeholder}' \
        -L \
        -H 'Content-Type: application/json' \
        -d @/tmp/minuet-request \
        https://example.test/v1/chat/completions)"
      [[ "$output" == response ]]
      touch "$out"
    '';
  };
}
