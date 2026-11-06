{ pkgs, inputs, ... }:
let
  # claude-code is unfree, so legacyPackages (no config) would refuse it.
  master = import inputs.nixpkgs-master {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (pkgs) config;
  };
  awsProfile = "tl";
  awsRegion = "us-west-2";
  aws = "${pkgs.awscli2}/bin/aws --profile ${awsProfile} --region ${awsRegion}";

  # Resolve the running dev box by its owner-email tag (the SSO session name),
  # since a rebuild changes its instance ID.
  devboxProxy = pkgs.writeShellScript "tl-devbox-proxy" ''
    set -euo pipefail
    export PATH="${pkgs.ssm-session-manager-plugin}/bin:$PATH"
    port="$1"
    arn=$(${aws} sts get-caller-identity --query Arn --output text)
    email="''${arn##*/}"
    id=$(${aws} ec2 describe-instances \
      --filters "Name=tag:service,Values=devbox" "Name=tag:owner-email,Values=$email" \
                "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[].InstanceId' --output text)
    if [ -z "$id" ]; then
      echo "tl-devbox: no running dev box tagged owner-email=$email" >&2
      exit 1
    fi
    exec ${aws} ssm start-session --target "$id" \
      --document-name AWS-StartSSHSession --parameters "portNumber=$port"
  '';
in
{
  # Company-managed: per-device keys instead of the age key (see README.md).
  dotfiles.secrets.enable = false;

  home = {
    packages = with pkgs; [
      ssm-session-manager-plugin
      jujutsu
      master.claude-code # the model gateway needs >= 2.1.307
    ];
    sessionVariables.AWS_PROFILE = awsProfile;
  };

  programs.ssh.settings."tl-devbox" = {
    User = "ubuntu";
    IdentityFile = "~/.ssh/tl-devbox";
    ProxyCommand = "${devboxProxy} %p";
    ServerAliveInterval = "30";
    ServerAliveCountMax = "3";
  };
}
