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

  defaults = {
    mcVersion = "1.21.1";
    version = "latest";
    loader = "neoforge";
  };

  fabric-1-21-11 = {
    mcVersion = "1.21.11";
    version = "latest";
    loader = "fabric";
  };
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
            string = if value == "all" then "" else builtins.toJSON [ value ];
            list = builtins.toJSON value;
          }
          .${builtins.typeOf value};

        jobs =
          lib.concatMapStringsSep "\n"
            (job: ''
              result/bin/update-fod "${job.name}" \
                '${job.loader}' \
                '${job.mcVersion}' \
                '${job.version}'
            '')
            (
              lib.mapAttrsToList (name: cfg: {
                inherit name;
                loader = getQueryValue cfg.loader;
                mcVersion = getQueryValue cfg.mcVersion;
                version = if cfg.version == "latest" then "latest" else getQueryValue cfg.version;
              }) projects
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

  config.projects = {
    # libs
    fabric-api = fabric-1-21-11;
    fabric-language-kotlin = fabric-1-21-11;
    addonslib = defaults;
    architectury-api = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    balm = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    cicada = fabric-1-21-11;
    servux = fabric-1-21-11;
    cristel-lib = defaults;
    curios = defaults;
    fzzy-config = defaults;
    gabous-libs = defaults;
    geckolib = defaults;
    glitchcore = defaults;
    gravestone-mod = defaults;
    lithostitched = defaults;
    moonlight = defaults;
    puzzles-lib = defaults;
    potentials = defaults;
    rpl = defaults;
    supermartijn642s-config-lib = defaults;
    supermartijn642s-core-lib = defaults;
    txnilib = defaults;
    yacl = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    yungs-api = defaults;
    zeta = defaults;
    owo-lib = defaults;
    kotlin-for-forge = defaults;
    badpackets = defaults;
    patchouli = defaults;
    titanium = defaults;
    mechanicals-lib = defaults;
    athena-ctm = defaults;
    dragonlib = defaults;
    glodium = defaults;
    forgified-fabric-api = defaults;
    "put-a-plug-in-it!" = defaults;
    sable = defaults;

    # general
    alloy-smelter = defaults;
    almostunified = defaults;
    betterdays = defaults;
    ct-overhaul-village = defaults;
    cloth-config = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    comforts = defaults;
    dungeons-and-taverns = {
      mcVersion = "all";
      version = "latest";
      loader = [
        "neoforge"
        "datapack"
      ];
    };
    joshs-more-foods = {
      mcVersion = "all";
      version = "latest";
      loader = "datapack";
    };
    mini-blocks-datapack = {
      mcVersion = "all";
      version = "latest";
      loader = "datapack";
    };
    enchanted-vertical-slabs = defaults;
    every-compat = defaults;
    leaves-be-gone = defaults;
    lets-do-herbalbrews = defaults;
    modern-industrialization = defaults;
    nullscape = defaults;
    polymorph = defaults;
    quark = defaults;
    rechiseled = defaults;
    reconnectible-chains = defaults;
    ribbits = defaults;
    serene-seasons = defaults;
    serene-seasons-plus = defaults;
    simply-swords = defaults;
    sound-physics-remastered = defaults;
    stone-zone = defaults;
    towns-and-towers = defaults;
    xaeros-minimap = defaults;
    xaeros-world-map = defaults;
    jade = defaults;
    jade-addons-forge = defaults;
    storagedrawers = defaults;
    industrial-foregoing = defaults;
    oritech = defaults;
    camerapture = defaults;
    immersive-ores = defaults;
    carry-on = defaults;
    bountiful-blocks = defaults;
    modular-routers = defaults;
    express-carts = fabric-1-21-11;

    # farmer's delight
    farmers-delight = defaults;
    farmers-knives = defaults;

    # sophisticated
    sophisticated-backpacks = defaults;
    sophisticated-storage = defaults;
    sophisticated-core = defaults;
    sophisticated-storage-in-motion = defaults;
    sophisticated-storage-create-integration = defaults;
    sophisticated-backpacks-create-integration = defaults;

    # stellaris
    stellaris = defaults;
    # tfmg-stellaris-compat = defaults;
    create-tfmg = defaults;

    # world gen
    tectonic = defaults;
    terralith-restoned = defaults;
    terralith = defaults;

    # emi
    emi = defaults;
    emi-ores = defaults;
    advanced-loot-info = defaults;

    # refined storage
    refined-storage = defaults;
    refined-types = defaults;
    refined-storage-quartz-arsenal = defaults;
    refined-storage-mekanism-integration = defaults;
    refined-storage-emi-integration = defaults;

    # applied energistics
    ae2 = defaults;
    applied-energistics-2-wireless-terminals = defaults;
    guideme = defaults;
    merequester = defaults;
    rechiseled-ae2 = defaults;
    mega = defaults;
    ae2-import-export-card = defaults;
    extended-ae = defaults;
    extendedae-plus = defaults;

    # mekanism
    mekanism = defaults;
    mekanism-tools = defaults;
    # mekanism-tfmg-compat
    mekanism-generators = defaults;
    mekanism-additions = defaults;
    applied-mekanistics = defaults;

    # performance and server stuff
    axiom = fabric-1-21-11;
    ledger = fabric-1-21-11;
    invview = fabric-1-21-11;
    entityculling = defaults;
    ferrite-core = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    immediatelyfast = defaults;
    modernfix = defaults;
    netherportalfix = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    no-chat-reports = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    noisiumforked = defaults;
    redirected = defaults;
    saturn = defaults;
    proxy-compatible-forge = defaults;
    chunky = defaults;
    bluemap = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = "latest";
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    bluemap-sign-markers = fabric-1-21-11;
    discord-mc-chat = fabric-1-21-11;
    fastevent = defaults;
    c2me-neoforge = defaults;
    smooth-boot = defaults;
    packet-fixer = defaults;
    fabricproxy-lite = fabric-1-21-11;
    simple-voice-chat = fabric-1-21-11;
    vmp-fabric = fabric-1-21-11;
    lithium = fabric-1-21-11;
    player-roles = fabric-1-21-11;
    krypton = fabric-1-21-11;
    c2me-fabric = fabric-1-21-11;
    image2map = fabric-1-21-11;
    scalablelux = fabric-1-21-11;
    do-a-barrel-roll = fabric-1-21-11;
    carpet = fabric-1-21-11;
    rei = fabric-1-21-11;

    # cc tweaked
    cc-tweaked = defaults;
    advancedperipherals = defaults;

    # create
    create = defaults;
    createaddition = defaults;
    bellsandwhistles = defaults;
    create-big-cannons = defaults;
    create-deco = defaults;
    create-diesel-generators = defaults;
    create-goggles = defaults;
    create-let-the-adventure-begin = defaults;
    createnuclear = defaults;
    create-ore-excavation = defaults;
    create-railways-navigator = defaults;
    slice-and-dice = defaults;
    create-central-kitchen = defaults;
    create-connected = defaults;
    copycats = defaults;
    create-dragons-plus = defaults;
    create-dreams-and-desires = defaults;
    create-drill-drain = defaults;
    create-enchantment-industry = defaults;
    interiors = defaults;
    create-new-age = defaults;
    create-polymer = defaults;
    create-threaded-trains = defaults;
    create-stellaris = defaults;
    create-design-n-decor = defaults;
    rechiseled-create = defaults;
    "create-steam-n-rails-1.21.1" = defaults;
    create-fd-dough = defaults;
    create-confectionery = defaults;
    create-factory = defaults;
    storage-drawers-create-compat = defaults;
    create-stock-bridge = defaults;
    create-bits-n-bobs = defaults;
    create-cobblestone = defaults;
    create-ultimate-factory = defaults;
    create-sifting = defaults;
    create-jetpack = defaults;
    cccbridge = defaults;
    delightful-creators = defaults;
    create-trading-floor = defaults;
    create-misc-and-things = defaults;
    "create-track-map-(unofficial-fork)" = defaults;
    create-aeronautics = defaults;

    # macaws
    macaws-bridges = defaults;
    macaws-doors = defaults;
    macaws-fences-and-walls = defaults;
    macaws-furniture = defaults;
    macaws-holidays = defaults;
    macaws-lights-and-lamps = defaults;
    macaws-paintings = defaults;
    macaws-paths-and-pavings = defaults;
    macaws-roofs = defaults;
    macaws-stairs = defaults;
    macaws-trapdoors = defaults;
    macaws-windows = defaults;
    macaws-quark = defaults;
  };
}
