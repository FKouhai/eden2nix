{
  description = "A basic AppImage bundler";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        eden = let
          appimage = pkgs.runCommand "eden-appimage" {} ''
            cp ${pkgs.fetchurl {
              url = "https://github.com/eden-emulator/Releases/releases/download/v0.0.3/Eden-Linux-v0.0.3-amd64.AppImage";
              sha256 = "0b1j8w0lw19d71dvyhs15scjw4rg6crcyjnj7kpsbg2jazak4r1z";
            }} $out
            chmod +x $out
          '';
          desktopFile = pkgs.runCommand "eden-desktop" {
            inherit appimage;
          } ''
            mkdir tmp
            cd tmp
            cp $appimage appimage
            ./appimage --appimage-extract
            mkdir -p $out/share/applications
            cp squashfs-root/dev.eden_emu.eden.desktop $out/share/applications/
            substituteInPlace $out/share/applications/dev.eden_emu.eden.desktop \
              --replace 'Exec=AppRun' 'Exec=eden'
          '';
        in
        pkgs.buildFHSEnv {
          name = "eden";
          targetPkgs = pkgs: with pkgs; [
            fuse
          ] ++ pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs pkgs;
          runScript = "${appimage}";
          extraInstallCommands = ''
            cp -r ${desktopFile}/share $out/
          '';
        };
      in
      with pkgs;
      {
        inherit eden;
        defaultPackage = eden;
      }
    );
}
