# strato-only home config (auto-imported by mkSystem): Trajectory Labs tooling.
{ pkgs, ... }:
let
  awsProfile = "tl";
  awsRegion = "us-west-2";
  aws = "${pkgs.awscli2}/bin/aws --profile ${awsProfile} --region ${awsRegion}";

  # Dev box instance IDs change when the box is rebuilt, so resolve the running
  # one on every connection by its owner-email tag. That email is the SSO user
  # the `tl` profile signs in as: the session name at the end of the role ARN.
  devboxProxy = pkgs.writeShellScript "tl-devbox-proxy" ''
    set -euo pipefail
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
  home = {
    packages = with pkgs; [
      ssm-session-manager-plugin # `aws ssm start-session`, behind ssh tl-devbox
      jujutsu # `tl task` composes tasks with jj
    ];
    # The `tl` profile itself comes from `aws configure sso` on the machine.
    sessionVariables.AWS_PROFILE = awsProfile;
  };

  programs.ssh.settings."tl-devbox" = {
    User = "ubuntu";
    ProxyCommand = "${devboxProxy} %p";
    ServerAliveInterval = "30";
    ServerAliveCountMax = "3";
  };
}
