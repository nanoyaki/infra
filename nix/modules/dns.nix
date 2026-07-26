{ inputs, ... }:

{
  flake.lib.dns =
    let
      inherit (inputs.self.lib.dns)
        coerceTtl
        coerceRecordList
        mkMailRecord
        mkA
        mkAAAA
        mkSPF
        mkSRV
        mkCNAME
        mkALIAS
        mkDKIM
        mkDMARC
        mkTXT
        mkMX
        ;
      inherit (builtins)
        attrValues
        toJSON
        isInt
        attrNames
        typeOf
        ;
      inherit (inputs.nixpkgs.lib)
        foldl'
        toUpper
        optionalString
        concatStringsSep
        filterAttrs
        mapAttrs
        recursiveUpdate
        ;
    in
    {
      mkDomainValues =
        domains: attr: fn:
        attrValues (
          foldl' (
            acc: entry:

            let
              value = entry.${attr};
            in

            if acc ? ${value} then acc else acc // { ${value} = fn value; }
          ) { } (attrValues domains)
        );

      mkProvider = provider: "var DSP_${toUpper provider} = NewDnsProvider(\"${provider}\");";
      mkRegistrar = registrar: "var REG_${toUpper registrar} = NewRegistrar(\"${registrar}\");";

      coerceRecordList =
        fn: records: map (record: fn ({ subdomain = record; } // records.${record})) (attrNames records);
      coerceTtl =
        value:
        optionalString (value != null) ", TTL(${if isInt value then toString value else "${value}"})";
      mkA = a: ''A("${a.subdomain}", IP("${a.address}")${coerceTtl a.ttl})'';
      mkAAAA = aaaa: ''AAAA("${aaaa.subdomain}", "${aaaa.address}"${coerceTtl aaaa.ttl})'';
      mkMX = mx: ''MX("${mx.subdomain}", ${toString mx.priority}, "${mx.value}"${coerceTtl mx.ttl})'';
      mkCNAME = cname: ''CNAME("${cname.subdomain}", "${cname.value}"${coerceTtl cname.ttl})'';
      mkALIAS = alias: ''ALIAS("${alias.subdomain}", "${alias.value}"${coerceTtl alias.ttl})'';
      mkSRV =
        srv:
        ''SRV("_${srv.service}._${srv.protocol}${
          optionalString (srv.subdomain != null) ".${srv.subdomain}"
        }", ${toString srv.priority}, ${toString srv.weight}, ${toString srv.port}, "${toString srv.target}")'';
      mkTXT = txt: ''TXT("${txt.subdomain}", "${txt.value}"${coerceTtl txt.ttl})'';
      mkMailRecord =
        record: fn:
        let
          options = filterAttrs (_: value: value != null && value != [ ]) (
            removeAttrs record [ "recordTtl" ]
          );
        in
        fn "${toJSON options}${coerceTtl record.recordTtl}";
      mkDKIM = dkim: mkMailRecord dkim (options: "DKIM_BUILDER(${options})");
      mkSPF = spf: mkMailRecord spf (options: "SPF_BUILDER(${options})");
      mkDMARC = dmarc: mkMailRecord dmarc (options: "DMARC_BUILDER(${options})");

      mkEntry =
        domains: name:

        let
          entry = domains.${name};
          args = concatStringsSep ",\n  " (
            [ ''DefaultTTL("${entry.defaultTtl}")'' ]
            ++ (coerceRecordList mkA entry.a)
            ++ (coerceRecordList mkAAAA entry.aaaa)
            ++ (map mkMX entry.mx)
            ++ (coerceRecordList mkCNAME entry.cname)
            ++ (coerceRecordList mkALIAS entry.alias)
            ++ (map mkSRV entry.srv)
            ++ (map mkDKIM entry.dkim)
            ++ (map mkDMARC entry.dmarc)
            ++ (map mkSPF entry.spf)
            ++ (map mkTXT entry.txt)
          );
        in

        ''''\nD("${name}", REG_${toUpper entry.registrar}, DnsProvider(DSP_${toUpper entry.provider}),''\n  ${args}''\n);'';

      mkCredsJson =
        credentials:

        toJSON (
          mapAttrs (
            _: endpoint:
            # Make sure to prefix the value and uppercase the type
            {
              TYPE = toUpper endpoint.type;
            }
            // (mapAttrs (_: value: "$" + value) (removeAttrs endpoint [ "type" ]))
          ) credentials
        );

      buildGlobalConfig =
        nixosConfigurations:

        foldl'
          (
            acc: host:

            if host ? config.programs.dnscontrol && host.config.programs.dnscontrol.domains != { } then
              let
                cfg = host.config.programs.dnscontrol;
              in
              recursiveUpdate acc {
                credentials = recursiveUpdate acc.credentials cfg.credentials;
                domains = mapAttrs (
                  domain: domainCfg:

                  mapAttrs (
                    record: recordCfg:

                    {
                      set = (acc.domains.${domain}.${record} or { }) // recordCfg;
                      list = (acc.domains.${domain}.${record} or [ ]) ++ recordCfg;
                    }
                    .${typeOf recordCfg} or recordCfg
                  ) domainCfg
                ) cfg.domains;
                extraConfig = "${acc.extraConfig}\n${cfg.extraConfig}";
              }
            else
              acc
          )
          {
            credentials = { };
            domains = { };
            extraConfig = "";
          }
          (attrValues nixosConfigurations);
    };

  flake.nixosModules.dns =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      inherit (inputs.self.lib.dns)
        mkEntry
        mkDomainValues
        mkProvider
        mkRegistrar
        mkCredsJson
        ;
      inherit (builtins) attrNames;
      inherit (lib)
        mkOption
        types
        concatLines
        all
        mapAttrs'
        replaceString
        ;

      ipv6Regex = "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))";
      ipv4Regex = ''((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'';
      mxRegex = ''([^.]+|.*\.)'';
      cnameRegex = ''([^.]+|.*\.|@)'';

      ttl = mkOption {
        type = types.nullOr (types.either types.str types.ints.positive);
        default = null;
      };

      subdomain = mkOption {
        type = types.str;
      };

      cfg = config.programs.dnscontrol;

      providers = mkDomainValues cfg.domains "provider" mkProvider;
      registrars = mkDomainValues cfg.domains "provider" mkRegistrar;
      entries = map (mkEntry cfg.domains) (attrNames cfg.domains);
    in

    {
      options.programs.dnscontrol = {
        credentialsFile = mkOption {
          type = types.path;
          default = pkgs.writeText "creds.json" (mkCredsJson cfg.credentials);
        };

        configFile = mkOption {
          type = types.path;
          default = pkgs.writeText "dnsconfig.js" ''
            ${concatLines (providers ++ registrars ++ entries)}
            ${cfg.extraConfig}
          '';
          readOnly = true;
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
        };

        credentials = mkOption {
          type = types.attrsOf (
            types.submodule {
              freeformType =
                with types;
                attrsOf (oneOf [
                  int
                  str
                  float
                  bool
                ]);

              options.type = mkOption {
                type = types.enum [ "porkbun" ];
                default = "porkbun";
              };
            }
          );
          default = { };
          example = lib.literalExpression ''
            {
              provider_id = {
                type = "porkbun";
                api_key = "EVNIRONMENT_VARIABLE_XYZ_1";
                secret_key = "SECRET_API_KEY_PROVIDER_1";
              };
              registrar_id = {
                type = "porkbun";
                api_key = "EVNIRONMENT_VARIABLE_XYZ_2";
                secret_key = "SECRET_API_KEY_PROVIDER_2";
              };
            }
          '';
          apply =
            credentials:
            mapAttrs' (name: value: {
              name = replaceString "-" "_" name;
              inherit value;
            }) credentials;
        };

        domains = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                provider = mkOption {
                  type = types.str;
                  default = "default";
                  apply = str: replaceString "-" "_" str;
                };

                registrar = mkOption {
                  type = types.str;
                  default = "default";
                  apply = str: replaceString "-" "_" str;
                };

                defaultTtl = mkOption {
                  type = types.either types.str types.ints.positive;
                  default = "1h";
                };

                a = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        inherit ttl;

                        address = mkOption {
                          type = types.strMatching ipv4Regex;
                        };
                      };
                    }
                  );
                  default = { };
                };

                aaaa = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        inherit ttl;

                        address = mkOption {
                          type = types.strMatching ipv6Regex;
                        };
                      };
                    }
                  );
                  default = { };
                };

                mx = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        inherit ttl subdomain;

                        priority = mkOption {
                          type = types.ints.positive;
                          default = 1;
                        };

                        value = mkOption {
                          type = types.strMatching mxRegex;
                        };
                      };
                    }
                  );
                  default = [ ];
                };

                cname = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        inherit ttl;

                        value = mkOption {
                          type = types.strMatching cnameRegex;
                        };
                      };
                    }
                  );
                  default = { };
                };

                alias = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        inherit ttl;

                        value = mkOption {
                          # Same as MX
                          type = types.strMatching mxRegex;
                        };
                      };
                    }
                  );
                  default = { };
                };

                srv = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        inherit ttl;

                        service = mkOption {
                          type = types.strMatching ''\w+'';
                        };

                        protocol = mkOption {
                          type = types.enum [
                            "tcp"
                            "udp"
                          ];
                        };

                        subdomain = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        port = mkOption {
                          type = types.port;
                        };

                        priority = mkOption {
                          # Between 0-65535
                          type = types.port;
                          default = 0;
                        };

                        weight = mkOption {
                          # Between 0-65535
                          type = types.port;
                          default = 5;
                        };

                        target = mkOption {
                          type = types.strMatching ''^(\w+\.)*\w+\.\w+\.$'';
                        };
                      };
                    }
                  );
                  default = [ ];
                };

                dkim = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        selector = mkOption {
                          type = types.str;
                        };

                        pubkey = mkOption {
                          type = types.str;
                        };

                        label = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        version = mkOption {
                          type = types.enum [ "DKIM1" ];
                          default = "DKIM1";
                        };

                        hashtypes = mkOption {
                          type = types.listOf (
                            types.enum [
                              "sha1"
                              "sha256"
                            ]
                          );
                          default = [ ];
                        };

                        keytype = mkOption {
                          type = types.enum [
                            "rsa"
                            "ed25519"
                          ];
                        };

                        note = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        servicetypes = mkOption {
                          type = types.listOf (
                            types.enum [
                              "email"
                              "*"
                            ]
                          );
                          default = [ ];
                        };

                        flags = mkOption {
                          type = types.listOf (
                            types.enum [
                              "y"
                              "s"
                            ]
                          );
                        };

                        inherit ttl;

                        recordTtl = ttl;
                      };
                    }
                  );
                  default = [ ];
                };

                spf = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        label = mkOption {
                          type = types.str;
                          default = "@";
                        };

                        overflow = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                          example = lib.literalExpression ''"_spf%d"'';
                        };

                        overhead1 = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        raw = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        txtMaxSize = mkOption {
                          type = types.nullOr types.ints.u8;
                          default = null;
                        };

                        parts = mkOption {
                          type = types.listOf types.str;
                        };

                        flatten = mkOption {
                          type = types.listOf types.str;
                          default = [ ];
                        };

                        inherit ttl;
                        recordTtl = ttl;
                      };
                    }
                  );
                  default = [ ];
                };

                dmarc = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        label = mkOption {
                          type = types.str;
                          default = "@";
                        };

                        version = mkOption {
                          type = types.enum [ "DMARC1" ];
                          default = "DMARC1";
                        };

                        policy = mkOption {
                          type = types.enum [
                            "none"
                            "quarantine"
                            "reject"
                          ];
                        };

                        subdomainPolicy = mkOption {
                          type = types.nullOr (
                            types.enum [
                              "none"
                              "quarantine"
                              "reject"
                            ]
                          );
                          default = null;
                        };

                        alignmentSPF = mkOption {
                          type = types.enum [
                            "strict"
                            "s"
                            "relaxed"
                            "r"
                          ];
                          default = "r";
                        };

                        alignmentDKIM = mkOption {
                          type = types.enum [
                            "strict"
                            "s"
                            "relaxed"
                            "r"
                          ];
                          default = "r";
                        };

                        percent = mkOption {
                          type = types.ints.between 0 100;
                          default = 100;
                        };

                        rua = mkOption {
                          type = types.listOf types.str;
                          default = [ ];
                        };

                        ruf = mkOption {
                          type = types.listOf types.str;
                          default = [ ];
                        };

                        failureOptions = mkOption {
                          type = types.either types.str (
                            types.submodule {
                              options = {
                                DKIM = mkOption {
                                  type = types.bool;
                                };

                                SPF = mkOption {
                                  type = types.bool;
                                };
                              };
                            }
                          );
                          default = "0";
                        };

                        failureFormat = mkOption {
                          type = types.str;
                          default = "afrf";
                        };

                        reportInterval = mkOption {
                          type = types.nullOr types.str;
                          default = null;
                        };

                        inherit ttl;
                        recordTtl = ttl;
                      };
                    }
                  );
                };

                txt = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        inherit subdomain ttl;

                        value = mkOption {
                          type = types.either types.str (types.listOf types.str);
                        };
                      };
                    }
                  );
                  default = [ ];
                };
              };
            }
          );
        };
      };

      config.assertions = [
        {
          assertion =
            cfg.domains != { }
            -> all (entry: (cfg.credentials ? ${entry.registrar}) && (cfg.credentials ? ${entry.provider})) (
              builtins.attrValues cfg.domains
            );
          message = ''
            One of the DNS entries is missing a registrar or provider definition
            as defined in {option}`config.services.dnscontrol.credentials` 
          '';
        }
      ];
    };

  perSystem =
    { lib, pkgs, ... }:

    {
      legacyPackages.dnscontrol =
        let
          inherit (lib) concatLines all;
          inherit (builtins) attrNames;
          inherit (inputs.self.lib.dns)
            mkDomainValues
            mkProvider
            mkRegistrar
            mkEntry
            mkCredsJson
            buildGlobalConfig
            ;

          globalConfig = buildGlobalConfig inputs.self.nixosConfigurations;
          domains =
            assert
              globalConfig.domains != { }
              -> all (
                entry:
                (globalConfig.credentials ? ${entry.registrar}) && (globalConfig.credentials ? ${entry.provider})
              ) (builtins.attrValues globalConfig.domains);
            globalConfig.domains;

          providers = mkDomainValues domains "provider" mkProvider;
          registrars = mkDomainValues domains "registrar" mkRegistrar;
          entries = map (mkEntry domains) (attrNames domains);
        in

        {
          creds-json = pkgs.writeText "creds.json" (mkCredsJson globalConfig.credentials);
          dnsconfig-js = pkgs.writeText "dnsconfig.js" ''
            ${concatLines (providers ++ registrars ++ entries)}
            ${globalConfig.extraConfig}
          '';
        };
    };
}
