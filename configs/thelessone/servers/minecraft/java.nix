{ lib, pkgs, ... }:

let
  getJava = pkg: lib.getExe' pkg "java";
in

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "java" ''
      JAVA_HOME=${pkgs.zulu21} ${getJava pkgs.zulu21} "$@"
    '')

    (pkgs.writeShellScriptBin "java21" ''
      JAVA_HOME=${pkgs.zulu21} ${getJava pkgs.zulu21} "$@"
    '')

    (pkgs.writeShellScriptBin "java17" ''
      JAVA_HOME=${pkgs.zulu17} ${getJava pkgs.zulu17} "$@"
    '')

    (pkgs.writeShellScriptBin "java8" ''
      JAVA_HOME=${pkgs.zulu8} ${getJava pkgs.zulu8} "$@"
    '')
  ];
}
