{pkgs, ...}: let
  version = "2.1.173";
  claude-code = pkgs.unstable.claude-code.overrideAttrs {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude";
      hash = "sha256-z36hlOF0iTL6MPGA6qn1b5pwOdzjcDApiMKSZimyohk=";
    };
  };
in {
  home.packages = [claude-code];
}
