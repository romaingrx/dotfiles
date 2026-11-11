{ pkgs, ... }:
let
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
  imports = [ ../../../modules/home/tl.nix ];

  # Company-managed: per-device keys instead of the age key (see README.md).
  dotfiles.secrets.enable = false;

  home = {
    packages = [ pkgs.ssm-session-manager-plugin ];
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
