{
  # Refer https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/README.md
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.enable = false;
  services.k3s = {
    enable = true;
    role = "server";
    token = "12345";
    clusterInit = true;
  };
}
