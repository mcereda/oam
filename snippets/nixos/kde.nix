{
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    xkb = {
      layout = "it";
      variant = "";
    };
  };
  services.displayManager.sddm.enable = true;
}
