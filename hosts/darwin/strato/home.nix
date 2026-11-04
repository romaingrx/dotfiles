# Work laptop (auto-imported by mkSystem). Personal secrets are off for this
# host (identity = "work" in flake.nix). Employer-specific values (work email,
# AWS SSO details) live in local files, never in this repo; see
# docs/new-host-setup.md.
{ pkgs, lib, ... }:
let
  awsProfile = "work";
  awsRegion = "us-west-2";

  # Dev box instance IDs change when the box is rebuilt, so resolve the running
  # one on every connection by its owner-email tag, which matches the work git
  # email from ~/.config/git/work.gitconfig.
  devboxProxy = pkgs.writeShellScript "devbox-proxy" ''
    set -euo pipefail
    port="$1"
    email=$(${pkgs.git}/bin/git config --global user.email)
    id=$(${pkgs.awscli2}/bin/aws ec2 describe-instances \
      --profile ${awsProfile} --region ${awsRegion} \
      --filters "Name=tag:service,Values=devbox" "Name=tag:owner-email,Values=$email" \
                "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[].InstanceId' --output text)
    if [ -z "$id" ]; then
      echo "devbox: no running dev box tagged owner-email=$email" >&2
      exit 1
    fi
    exec ${pkgs.awscli2}/bin/aws ssm start-session --target "$id" \
      --document-name AWS-StartSSHSession --parameters "portNumber=$port" \
      --profile ${awsProfile} --region ${awsRegion}
  '';
in
{
  home = {
    packages = with pkgs; [
      ssm-session-manager-plugin # `aws ssm start-session`, behind ssh devbox
      jujutsu
    ];
    # The `work` profile itself comes from `aws configure sso` on the machine.
    sessionVariables.AWS_PROFILE = awsProfile;
  };

  programs.ssh.settings = {
    # The work key is generated on the laptop (ssh-keygen -t ed25519) and added
    # to GitHub for auth + signing; the personal ~/.ssh/github key is not here.
    "github.com".IdentityFile = lib.mkForce "~/.ssh/id_ed25519";
    "devbox" = {
      User = "ubuntu";
      IdentityFile = "~/.ssh/id_ed25519";
      ProxyCommand = "${devboxProxy} %p";
      ServerAliveInterval = "30";
      ServerAliveCountMax = "3";
    };
  };
}
