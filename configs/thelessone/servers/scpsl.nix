{ inputs, ... }:

{
  imports = [ inputs.nix-scpsl.nixosModules.default ];

  services.scpsl-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    servers."7777" = {
      settings = {
        server_name = "Thelessone SCPSL";
        lobby_waiting_time = 30;
        late_join_time = 10;
        contact_email = "scpsl@theless.one";

        friendly_fire = true;
        friendly_fire_multiplier = 0.6;

        broadcast_kicks = true;
        ff_detector_round_action = "kick";
        ff_detector_life_action = "kick";
        ff_detector_window_action = "kick";
        ff_detector_spawn_action = "kick";
        ff_detector_explosion_after_disconnecting_enabled = false;
        ff_detector_classD_can_damage_classD = true;

        intercom_cooldown = 60;
        intercom_max_speech_time = 30;
        stamina_balance_use = 0.04;
      };

      adminSettings = {
        Members = [
          { "76561198319877798@steam" = "owner"; }
          { "76561198294979887@steam" = "admin"; }
        ];

        owner_badge = "Admin";
        owner_hidden = true;

        admin_badge = "Admin";
        admin_hidden = true;

        moderator_badge = "Moderator";
        moderator_hidden = true;
      };
    };
  };
}
