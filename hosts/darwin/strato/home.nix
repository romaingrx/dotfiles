{ pkgs, inputs, ... }:
let
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  awsProfile = "tl";
  awsRegion = "us-west-2";
  aws = "${pkgs.awscli2}/bin/aws --profile ${awsProfile} --region ${awsRegion}";

  # Resolve a running dev box by its owner-email tag (the SSO session name) and its
  # devbox-tier tag, since a rebuild changes its instance ID.
  # Usage: tl-devbox-proxy <port> <regular|admin>
  devboxProxy = pkgs.writeShellScript "tl-devbox-proxy" ''
    set -euo pipefail
    export PATH="${pkgs.ssm-session-manager-plugin}/bin:$PATH"
    port="$1"
    tier="$2"

    # Refuse a login that resolved to another account than the profile names.
    expected=$(${aws} configure get sso_account_id)
    read -r account arn < <(${aws} sts get-caller-identity --query '[Account,Arn]' --output text)
    if [ "$account" != "$expected" ]; then
      echo "tl-devbox: logged in to account $account, but profile ${awsProfile} names $expected" >&2
      exit 1
    fi
    email="''${arn##*/}"

    # A box without a devbox-tier tag is the regular one.
    ids=$(${aws} ec2 describe-instances \
      --filters "Name=tag:service,Values=devbox" "Name=tag:owner-email,Values=$email" \
                "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[].[InstanceId, (Tags[?Key==`devbox-tier`].Value)[0]]' \
      --output text |
      awk -v tier="$tier" '{ t = ($2 == "None" ? "regular" : $2) } t == tier { print $1 }')
    case "$(printf '%s' "$ids" | grep -c .)" in
      1) ;;
      0) echo "tl-devbox: no running $tier dev box tagged owner-email=$email" >&2; exit 1 ;;
      *) echo "tl-devbox: several running $tier dev boxes for $email:" $ids >&2; exit 1 ;;
    esac
    exec ${aws} ssm start-session --target "$ids" \
      --document-name AWS-StartSSHSession --parameters "portNumber=$port"
  '';

  devboxHost = tier: {
    User = "ubuntu";
    IdentityFile = "~/.ssh/tl-devbox";
    # The key has a passphrase and lives in gpg-agent. Name the agent here so that
    # background services without SSH_AUTH_SOCK (herdr-core) can reconnect too.
    IdentityAgent = "~/.gnupg/S.gpg-agent.ssh";
    ProxyCommand = "${devboxProxy} %p ${tier}";
    ServerAliveInterval = "30";
    ServerAliveCountMax = "3";
  };

  tailscaleHost = hostName: {
    HostName = hostName;
    User = "ubuntu";
    IdentityFile = "~/.ssh/tl-devbox";
    IdentityAgent = "~/.gnupg/S.gpg-agent.ssh";
  };
in
{
  imports = [
    ../../../modules/home/tl.nix
    ../../../modules/home/claude-gateway.nix
    ../../../modules/home/baton-app.nix
    ../../../modules/home/baton-settings.nix
  ];

  # Company-managed: per-device keys instead of the age key (see README.md).
  dotfiles.secrets.enable = false;

  home = {
    packages = [
      master.herdr
      pkgs.google-cloud-sdk
      pkgs.mosh
      pkgs.ssm-session-manager-plugin
    ];
    sessionVariables.AWS_PROFILE = awsProfile;
  };

  programs.ssh.settings = {
    "tl-devbox" = devboxHost "regular";
    "tl-admin-devbox" = devboxHost "admin";

    # The same boxes over Tailscale, for mosh: its UDP can't ride the SSM tunnel.
    "tl-devbox-ts" = tailscaleHost "devbox-romain-graux";
    "tl-admin-devbox-ts" = tailscaleHost "devbox-romain";
  };
}
