{ config, lib, pkgs, hostname, ... }:

{
  # Scheduler for CachyOS-Kernel
  services.scx.enable = true;
}
