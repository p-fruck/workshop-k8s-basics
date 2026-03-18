{
  description = "Dev shell to export slides";
  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          weasyprint
        ]);
      in
      pkgs.mkShell {
        packages = [
          pkgs.docker-compose
          pkgs.inconsolata
          pkgs.just
          pkgs.pandoc
          pkgs.presenterm
          (pkgs.writeShellScriptBin "mmdc" ''
            exec ${pkgs.nodePackages.mermaid-cli}/bin/mmdc \
              -p ${./puppeteer.json} \
              "$@"
          '')
          pkgs.typst
          pythonEnv
        ];
      };
  };
}
