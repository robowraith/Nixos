{config, ...}: {
  programs.helix = {
    enable = true;

    # 2. Settings from your config.toml
    settings = {
      editor = {
        auto-format = true;
        color-modes = true;
        cursorline = true;
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
        whitespace.render = "all";
      };
      keys = {
        insert.C-s = ":write";
        insert.C-q = ":quit";
        normal.C-s = ":write";
        normal.C-q = ":quit";
      };
    };

    # 3. Language configuration from your languages.toml
    languages = {
      language-server = {
        gpt = {
          command = "${config.home.homeDirectory}/Privat/code/helix-gpt/dist/helix-gpt";
          # IMPORTANT: The API key is read from an environment variable for security.
          # You must set this variable in your shell for it to work, for example:
          # export COPILOT_API_KEY="ghp_..."
          args = [
            "--handler"
            "copilot"
            "--copilotApiKey"
            (builtins.getEnv "COPILOT_API_KEY")
          ];
        };
        go = {
          command = "gopls";
        };
        pylsp = {
          command = "pylsp";
        };
        jedi = {
          command = "jedi-language-server";
        };
        ruff = {
          command = "ruff";
        };
      };
      language = [
        {
          name = "go";
          language-servers = ["go"];
        }
        {
          name = "puppet";
          scope = "source.puppet";
          file-types = ["pp"];
          language-servers = ["solargraph"];
        }
        {
          name = "python";
          language-servers = ["pylsp" "ruff" "jedi-language-server"];
        }
        {
          name = "yaml";
          file-types = ["yaml" "yml"];
          language-servers = ["yaml"];
        }
      ];
    };
  };
}
