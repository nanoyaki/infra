_:

# lib.filterAttrs (_: cfg: cfg ? serviceConfig.Type && cfg.serviceConfig.Type != "oneshot" || (!(cfg ? serviceConfig.Type))) config.systemd.services

{

}
