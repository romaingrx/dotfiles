{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "2.4.1";
  sources = {
    x86_64-linux = {
      platform = "Linux_x86_64";
      hash = "sha256-+E9yreK5LLRs8C4GNGfKrwDGPQ+PnVwSMspVi0LpcbE=";
    };
    aarch64-linux = {
      platform = "Linux_arm64";
      hash = "sha256-SjsOiqZCWg4pvjG/GMo25QroeUGudMc6jgWWYytitpo=";
    };
    aarch64-darwin = {
      platform = "Darwin_arm64";
      hash = "sha256-1TUqgLuoBSdQuh9ftj/MHqHI/X8QT4dypRmlVb/nOl0=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "datadog-pup: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "datadog-pup";
  inherit version;

  src = fetchurl {
    url = "https://github.com/DataDog/pup/releases/download/v${version}/pup_${version}_${source.platform}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 pup $out/bin/pup
    runHook postInstall
  '';

  meta = {
    description = "Datadog CLI for agents and humans";
    homepage = "https://github.com/DataDog/pup";
    license = lib.licenses.asl20;
    mainProgram = "pup";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
