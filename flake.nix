{
  description = "DS5Dongle – Pico2W DualSense 5 Bridge development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # GitHub release tarballs – no git history, ~20MB vs ~100MB
      fetch = builtins.fetchTarball;

      pico-sdk-src = fetch {
        url = "https://github.com/raspberrypi/pico-sdk/archive/refs/tags/2.2.0.tar.gz";
        sha256 = "1wxdp8bwmnvv7aakf1pq1hwr3qbcdyzmxy9k9g5wkz9q7xj481w5";
      };

      btstack-src = fetch {
        url = "https://github.com/bluekitchen/btstack/archive/501e6d2b86e6c92bfb9c390bcf55709938e25ac1.tar.gz";
        sha256 = "0yxx0jjidvqq4q5vqg8bay1zn537l3sqw45rnfdmrqkghldd7h1v";
      };

      cyw43-driver-src = fetch {
        url = "https://github.com/georgerobotics/cyw43-driver/archive/dd7568229f3bf7a37737b9e1ef250c26efe75b23.tar.gz";
        sha256 = "0p54ihgakcpp52rn3x2snak9p8rwyri1lczvipr0548y8xw6ks6z";
      };

      lwip-src = fetch {
        url = "https://github.com/lwip-tcpip/lwip/archive/77dcd25a72509eb83f72b033d219b1d40cd8eb95.tar.gz";
        sha256 = "0zikm39my8i9fwm08317b8fc803gbxjxvd2xvsax9gyd0591ndpi";
      };

      mbedtls-src = fetch {
        url = "https://github.com/Mbed-TLS/mbedtls/archive/107ea89daaefb9867ea9121002fbbdf926780e98.tar.gz";
        sha256 = "1vgrf99nag96lvs21457islbiplyqfx6gyim959bz4zixh0hwa0a";
      };

      tinyusb-src = fetch {
        url = "https://github.com/hathach/tinyusb/archive/refs/tags/0.20.0.tar.gz";
        sha256 = "099r8i4qad56jabkdwl9bmllgcqkya218p3y7y27kn8xa04m8nds";
      };

      # Assemble pico-sdk with all submodules and tinyusb 0.20.0
      pico-sdk-patched = pkgs.runCommand "pico-sdk-2.2.0-tinyusb-0.20.0" {}
        ''
          # Copy pico-sdk main source (tarball extracts directly, no wrapper dir)
          cp -r ${pico-sdk-src} $out
          chmod -R u+w $out

          # Replace empty submodule stubs with actual source code
          rm -rf $out/lib/btstack
          cp -r ${btstack-src} $out/lib/btstack

          rm -rf $out/lib/cyw43-driver
          cp -r ${cyw43-driver-src} $out/lib/cyw43-driver

          rm -rf $out/lib/lwip
          cp -r ${lwip-src} $out/lib/lwip

          rm -rf $out/lib/mbedtls
          cp -r ${mbedtls-src} $out/lib/mbedtls

          rm -rf $out/lib/tinyusb
          cp -r ${tinyusb-src} $out/lib/tinyusb
        '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "ds5-dongle";

        buildInputs = with pkgs; [
          cmake
          ninja
          python3
          git
          gcc-arm-embedded-14
        ];

        shellHook = ''
          export PICO_SDK_PATH="${pico-sdk-patched}"
          echo "[nix] PICO_SDK_PATH=$PICO_SDK_PATH"
        '';
      };
    };
}
