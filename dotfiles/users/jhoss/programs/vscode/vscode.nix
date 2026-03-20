{
  pkgs,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions;
      [
        redhat.ansible
        redhat.vscode-yaml
        samuelcolvin.jinjahtml
        ms-vscode-remote.remote-containers
        github.copilot
        github.copilot-chat
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-helix-emulation";
          publisher = "jasew";
          version = "0.7.0";
          sha256 = "1diwv1q1z8kkx9v0jzzfb5sa5v9825dx872di9k0px66fmb8i341";
        }
        {
          name = "gitlab-workflow";
          publisher = "GitLab";
          version = "6.71.9";
          sha256 = "0rs9r09xzbxqn7fh1sxmr2zsw7zxxddi278ccymj9picvs6lvvpk";
        }
      ];

    profiles.default.userSettings = {
      # Font configuration
      "editor.fontFamily" = lib.mkForce "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace', monospace";
      "editor.fontLigatures" = true;
      "editor.inlayHints.fontFamily" = lib.mkForce "FiraCode Nerd Font";
      "terminal.integrated.fontFamily" = lib.mkForce "FiraCode Nerd Font";
      "chat.editor.fontFamily" = lib.mkForce "FiraCode Nerd Font";
      "scm.inputFontFamily" = lib.mkForce "FiraCode Nerd Font";
      "markdown.preview.fontFamily" = lib.mkForce "FiraCode Nerd Font";
      "debug.console.fontFamily" = lib.mkForce "FiraCode Nerd Font";
      "notebook.output.fontFamily" = lib.mkForce "FiraCode Nerd Font";

      # Disable RedHat telemetry
      "ansible.lightspeed.enabled" = false;
      "redhat.telemetry.enabled" = false;

      # General settings
      "workbench.startupEditor" = "none";
      "remote.autoForwardPortsSource" = "hybrid";

      # GitLab extension settings (pre-populated so the read-only settings.json is not an issue)
      ## "gitlab.instanceUrl" = "https://git.42he.com";
      ## "gitlab.showStatusBarLinks" = true;
      ## "gitlab.showIssueLinkOnStatusBar" = true;
      ## "gitlab.showMrStatusOnStatusBar" = true;
      ## "gitlab.aiAssistedCodeSuggestions.enabled" = false;
      "gitlab.duoCodeSuggestions.enabled" = false;
      "gitlab.duoChat.enabled" = false;
      "gitlab.duoAgentPlatform.enabled" = false;
      "gitlab.duo.enabledWithoutGitlabProject" = false;
      # "gitlab.duoAgentPlatform.defaultNamespace" = "test";
      "gitlab.keybindingHints.enabled" = false;
      "gitlab.duoCodeSuggestions.openTabsContext" = false;
      "gitlab.duoAgentPlatform.editFileDiffBehavior" = "foreground";
      # "gitlab.ca" = "test";
      # "gitlab.cert" = "test";
      # "gitlab.certKey" = "test";
      "gitlab.ignoreCertificateErrors" = false;
      "gitlab.real-timeSecurityScan.enabled" = false;
      "gitlab.real-timeSecurityScan.scanFileOnSave" = true;
      "gitlab.featureFlags.flowBuilder" = false;
      "gitlab.debug" = false;
      "gitlab.branchProtection" = true;
      # "gitlab.pipelineGitRemoteName" = "test";
      "gitlab.showClosedMergeRequests" = true;
      "gitlab.showPipelineUpdateNotifications" = true;
    };

    # Hyper key (Shift+Ctrl+Alt+Meta) keybindings
    profiles.default.keybindings = [
      # Hyper+C — AI Chat: focus when not visible/focused, hide when focused
      {
        key = "shift+ctrl+alt+meta+c";
        command = "workbench.action.chat.open";
        when = "!(panelFocus && activePanel == 'workbench.panel.chat')";
      }
      {
        key = "shift+ctrl+alt+meta+c";
        command = "workbench.action.togglePanel";
        when = "panelFocus && activePanel == 'workbench.panel.chat'";
      }

      # Hyper+E — Editor: focus when not focused, cycle to next editor when focused
      {
        key = "shift+ctrl+alt+meta+e";
        command = "workbench.action.focusActiveEditorGroup";
        when = "!editorFocus";
      }
      {
        key = "shift+ctrl+alt+meta+e";
        command = "workbench.action.nextEditorInGroup";
        when = "editorFocus";
      }

      # Hyper+T — Terminal: focus when not focused, hide when focused and single terminal, cycle next when multiple
      {
        key = "shift+ctrl+alt+meta+t";
        command = "workbench.action.terminal.focus";
        when = "!terminalFocus";
      }
      {
        key = "shift+ctrl+alt+meta+t";
        command = "workbench.action.terminal.focusNext";
        when = "terminalFocus && terminalCount > 1";
      }
      {
        key = "shift+ctrl+alt+meta+t";
        command = "workbench.action.togglePanel";
        when = "terminalFocus && terminalCount <= 1";
      }

      # Hyper+F — File Explorer: focus when not focused, hide when focused
      {
        key = "shift+ctrl+alt+meta+f";
        command = "workbench.view.explorer";
        when = "!sideBarVisible || focusedView != 'workbench.explorer.fileView'";
      }
      {
        key = "shift+ctrl+alt+meta+f";
        command = "workbench.action.toggleSidebarVisibility";
        when = "sideBarVisible && focusedView == 'workbench.explorer.fileView'";
      }
    ];
  };
}
