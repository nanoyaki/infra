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

  mei = version: {
    mcVersion = "1.21.1";
    inherit version;
    loader = "neoforge";
  };
in

{
  options.projects = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:

        {
          options = {
            id = mkOption {
              type = types.str;
              default = name;
            };

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
      )
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
              lib.mapAttrsToList (_: cfg: {
                name = cfg.id;
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
    fzzy-config = defaults;
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
    badpackets = defaults;
    patchouli = defaults;
    titanium = defaults;
    "put-a-plug-in-it!" = defaults;
    sable = defaults;

    # general
    alloy-smelter = defaults;
    ct-overhaul-village = defaults;
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
    leaves-be-gone = defaults;
    modern-industrialization = defaults;
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
    modular-routers = defaults;
    express-carts = fabric-1-21-11;

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
    applied-energistics-2-wireless-terminals = defaults;
    rechiseled-ae2 = defaults;

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
    advancedperipherals = defaults;

    # create
    create-drill-drain = defaults;
    create-polymer = defaults;
    create-threaded-trains = defaults;
    create-stellaris = defaults;
    rechiseled-create = defaults;
    create-fd-dough = defaults;
    create-confectionery = defaults;
    storage-drawers-create-compat = defaults;
    create-stock-bridge = defaults;
    create-jetpack = defaults;
    cccbridge = defaults;
    "create-track-map-(unofficial-fork)" = defaults;

    # macaws
    macaws-bridges = defaults;
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

    lets-do-brewery-farmcharm-compat = mei "2.1.9";
    lets-do-farm-charm = mei "1.1.23";
    lets-do-furniture = mei "1.1.4";
    lets-do-herbalbrews = mei [
      # default
      "latest"
      # mei
      "1.1.3"
    ];
    lets-do-vinery = mei "1.5.3";
    lets-do-wildernature = mei "1.1.5";
    addonslib = mei [
      # default
      "latest"
      # mei
      "1.21.1-1.14"
    ];
    ae2-import-export-card = mei [
      # default
      "latest"
      # mei
      "1.21.1-1.5.0"
    ];
    aerocopycats = (mei "1.1.0") // {
      id = "wjpmYU1u";
    };
    aeroengine = mei "1.0.2";
    almostunified = mei [
      "latest"
      "1.21.1-1.4.2 "
    ];
    ae2 = mei [
      # default
      "latest"
      # mei
      "19.2.17"
    ];
    architectury-api = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = [
        # default
        "latest"
        # mei
        "13.0.11"
      ];
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    athena-ctm = mei [
      # default
      "latest"
      # mei
      "4.0.6"
    ];
    azimuth-api = mei [
      # default
      "latest"
      # mei
      "1.4.7"
    ];
    better-library = mei [
      # default
      "latest"
      # mei
      "1.0.111"
    ];
    betterdays = mei [
      # default
      "latest"
      # mei
      "3.3.6.3"
    ];
    biomes-o-plenty = mei [
      # default
      "latest"
      # mei
      "21.1.0.14"
    ];
    bountiful-blocks = mei [
      # default
      "latest"
      # mei
      "0.9.9"
    ];
    cc-tweaked = mei [
      # default
      "latest"
      # mei
      "1.120.2"
    ];
    chipped = mei [
      # default
      "latest"
      # mei
      "4.0.2"
    ];
    cloth-config = {
      mcVersion = [
        "1.21.11"
        "1.21.1"
      ];
      version = [
        # default
        "latest"
        # mei
        "15.0.140"
      ];
      loader = [
        "neoforge"
        "fabric"
      ];
    };
    comforts = mei [
      # default
      "latest"
      # mei
      "9.0.5+1.21.1"
    ];
    create = mei [
      # default
      "latest"
      # mei
      "6.0.10"
    ];
    create-aeronautics = mei [
      # default
      "latest"
      # mei
      "1.3.1"
    ];
    create-aeronautics-lift-patch = mei "1.0.0";
    create-aeronautics-transmission-linkage = mei "0.2.7";
    create-big-cannons = mei [
      # default
      "latest"
      # mei
      "5.11.7"
    ];
    # use tfmg ce
    create-bits-n-bobs = mei [
      # default
      "latest"
      # mei
      "2.2.7"
    ];
    create-cobblestone = mei [
      # default
      "latest"
      # mei
      "1.4.12+neoforge-1.12.1-144"
    ];
    createaddition = mei [
      # default
      "latest"
      # mei
      "1.7.0"
    ];
    create-deco = mei [
      # default
      "latest"
      # mei
      "2.1.3"
    ];
    create-diesel-generators = mei [
      # default
      "latest"
      # mei
      "1.21.1-1.3.15"
    ];
    create-encased = mei "1.9.0-ht3";
    create-goggles = mei [
      # default
      "latest"
      # mei
      "6.1.1"
    ];
    create-let-the-adventure-begin = mei [
      # default
      "latest"
      # mei
      "4.1.0"
    ];
    createnuclear = mei [
      # default
      "latest"
      # mei
      "1.3.2-beta.3"
    ];
    create-ore-excavation = mei [
      # default
      "latest"
      # mei
      "1.6.8"
    ];
    create-propulsion-simulated = mei "1.1.5";
    create-railways-navigator = mei "1.21.1-beta-0.9.1-C6";
    create-sifting = mei [
      # default
      "latest"
      # mei
      "1.21.1-2.2.2"
    ];
    slice-and-dice = mei [
      # default
      "latest"
      # mei
      "4.3.3"
    ];
    create-aeroworks = mei "1.4.2";
    bellsandwhistles = mei [
      # default
      "latest"
      # mei
      "0.4.7-1.21.1"
    ];
    create-bits-n-dyes = mei "1.1.2";
    create-central-kitchen = mei [
      # default
      "latest"
      # mei
      "2.6.0"
    ];
    create-compatible-storage = mei "2.13.0";
    create-connected = mei [
      # default
      "latest"
      # mei
      "1.3.2-mc1.21.1"
    ];
    copycats = mei [
      # default
      "latest"
      # mei
      "3.0.8+mc.1.21.1-neoforge"
    ];
    create-dragons-plus = mei [
      # default
      "latest"
      # mei
      "1.11.7b"
    ];
    create-dreams-and-desires = mei [
      # default
      "latest"
      # mei
      "2.3a-BETA"
    ];
    create-enchantment-industry = mei [
      # default
      "latest"
      # mei
      "2.5.3"
    ];
    escalated = mei "1.3.2";
    create-factory = mei [
      # default
      "latest"
      # mei
      "0.7b-1.21.1"
    ];
    create-food = mei "2.7.1";
    create-garnished = mei "2.1.9.2";
    interiors = mei [
      # default
      "latest"
      # mei
      "0.6.1"
    ];
    create-new-age = mei [
      # default
      "latest"
      # mei
      "1.2.0+mc1.21.1"
    ];
    numismatics = mei "1.0.20+neoforge-mc1.21.1";
    create-steam-n-rails =
      (mei [
        # default
        "latest"
        # mei
        "0.3.0-beta.2+neoforge-mc1.21.1"
      ])
      // {
        id = "create-steam-n-rails-1.21.1";
      };
    # TFMG HERE
    create-misc-and-things = mei [
      # default
      "latest"
      # mei
      "4.1.1"
    ];
    create-trading-floor = mei [
      # default
      "latest"
      # mei
      "3.0.16"
    ];
    create-transmission = (mei "1.2.2+neoforge-create6-1.21.1") // {
      id = "create-transmission!";
    };
    create-ultimate-factory = mei [
      # default
      "latest"
      # mei
      "1.9.0"
    ];
    create-better-villagers = mei "1.3.0";
    critters-and-companions = mei "2.7.0";
    curios = mei [
      # default
      "latest"
      # mei
      "9.5.1+1.21.1"
    ];
    delight-lib = mei "26.05.18-1.21-neoforge";
    delightful-creators = mei [
      # default
      "latest"
      # mei
      "1.2.1"
    ];
    create-design-n-decor = mei [
      # default
      "latest"
      # mei
      "2.2b"
    ];
    dragonlib = mei [
      # default
      "latest"
      # mei
      "1.21.1-beta-3.0.28"
    ];
    dungeons-and-taverns = {
      mcVersion = "all";
      version = [
        "latest"
        "1-v4.4.4"
      ];
      loader = [
        "neoforge"
        "datapack"
      ];
    };
    enchanted-vertical-slabs = mei [
      # default
      "latest"
      # mei
      "2.3.2"
    ];
    every-compat = mei [
      # default
      "latest"
      # mei
      "1.21-2.11.50"
    ];
    extended-ae = mei [
      # default
      "latest"
      # mei
      "1.21-2.2.35-neoforge"
    ];
    extendedae-plus = mei [
      # default
      "latest"
      # mei
      "1.6.1"
    ];
    # farmer's delight
    farmers-delight = mei [
      # default
      "latest"
      # mei
      "1.3.3"
    ];
    farmers-knives = mei [
      # default
      "latest"
      # mei
      "1.21.1-4.2.0"
    ];
    forgified-fabric-api = mei [
      # default
      "latest"
      # mei
      "0.116.15+2.3.5+1.21.1"
    ];
    fusion-connected-textures = mei "1.3.14+a";
    gabous-libs = mei [
      # default
      "latest"
      # mei
      "1.8.3"
    ];
    geckolib = mei [
      # default
      "latest"
      # mei
      "4.9.2"
    ];
    glitchcore = mei [
      # default
      "latest"
      # mei
      "2.1.0.2"
    ];
    glodium = mei [
      # default
      "latest"
      # mei
      "1.21-2.2-neoforge"
    ];
    gravestone-mod = mei [
      # default
      "latest"
      # mei
      "1.21.1-1.0.40"
    ];
    guideme = mei [
      # default
      "latest"
      # mei
      "21.1.17"
    ];
    immersive-melodies = mei "0.7.1+1.21.1";
    kotlin-for-forge = mei [
      # default
      "latest"
      # mei
      "5.12.0"
    ];
    lithostitched = mei [
      # default
      "latest"
      # mei
      "1.8.0+beta4"
    ];
    macaws-doors = mei [
      # default
      "latest"
      # mei
      "1.1.5"
    ];
    macaws-quark = mei [
      # default
      "latest"
      # mei
      "1.21.1-1.6.1"
    ];
    mafglib = mei "0.4.3+mc1.21.1";
    merequester = mei "1.21.1-1.4.3";
    mechanicals-lib = mei [
      # default
      "latest"
      # mei
      "1.1.6"
    ];
    mega = mei [
      # default
      "latest"
      # mei
      "4.11.0"
    ];
    moonlight = mei [
      # default
      "latest"
      # mei
      "1.21.1-3.5.0"
    ];
    more-delight = mei "26.05.20a-1.21-neoforge";
    nullscape = mei [
      # default
      "latest"
      # mei
      "1.2.14"
    ];
  };
}
