{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;

  versionType = types.strMatching ''(1\.[0-9]{1,2}\.[0-9]{1,2}|(2[6-9]|[3-9][0-9])\.[1-4].[0-9]+)'';
  loaders = [
    "fabric"
    "neoforge"
    "datapack"
  ];
in

{
  options.projects = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          mcVersion = mkOption {
            type = types.oneOf [
              (types.enum [
                "latest"
                "all"
              ])
              versionType
              (types.listOf versionType)
            ];
            default = "all";
          };

          version = mkOption {
            type = types.oneOf [
              (types.enum [
                "latest"
                "all"
              ])
              types.str
              (types.listOf types.str)
            ];
            default = "all";
          };

          loader = mkOption {
            type = types.either (types.enum (loaders ++ [ "all" ])) (types.listOf (types.enum loaders));
            default = "all";
          };
        };
      }
    );
    default = { };
    apply =
      projects:

      let
        getQueryValue =
          value:
          {
            string = if value == "" then "" else builtins.toJSON [ value ];
            list = builtins.toJSON value;
          }
          .${builtins.typeOf value};

        jobs = lib.concatStringsSep "\n" (
          lib.flatten (
            map
              (lib.attrsets.mapCartesianProduct (job: ''
                result/bin/update-fod "${job.name}" \
                  '${getQueryValue (job.loader or "")}' \
                  '${getQueryValue (job.mcVersion or "")}' \
                  '${job.version or ""}'
              ''))
              (
                map (
                  combo:

                  {
                    inherit (combo) name;
                  }
                  // (lib.optionalAttrs (combo.mcVersion != "all") {
                    mcVersion = if builtins.isList combo.mcVersion then combo.mcVersion else [ combo.mcVersion ];
                  })
                  // (lib.optionalAttrs (combo.version != "all") {
                    version = if builtins.isList combo.version then combo.version else [ combo.version ];
                  })
                  // (lib.optionalAttrs (combo.loader != "all") {
                    loader = if builtins.isList combo.loader then combo.loader else [ combo.loader ];
                  })
                ) (lib.mapAttrsToList (name: attrs: attrs // { name = [ name ]; }) projects)
              )
          )
        );
      in

      ''
        [[ ! -f "flake.nix" ]] && { echo "Please run this script in the project's root!"; exit 1; }
        pushd nix/configs/thelessone/servers/games/minecraft/projects

        rm _sources/*
        nix build .#update-fod
        ${jobs}

        rm result
        popd
      '';
  };

  config.projects = import ./_projects.nix;
}
