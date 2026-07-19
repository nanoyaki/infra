{
  flake.nixosModules.sumire-knot-resolver =
    { lib, ... }:

    {
      services.resolved.enable = lib.mkForce false;

      services.knot-resolver.enable = true;
      services.knot-resolver.settings = {
        workers = "auto";
        views = [
          {
            subnets = [
              "0.0.0.0/0"
              "::/0"
            ];
            answer = "refused";
          }
          {
            subnets = [
              "127.0.0.0/24"
              "::1/128"
            ];
            answer = "allow";
          }
        ];
      };
    };
}
