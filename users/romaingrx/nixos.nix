{ ... }: {
  users.users.romaingrx = {
    isNormalUser = true;
    home = "/home/romaingrx";
    extraGroups = [ "wheel" "networkmanager" ];
    createHome = true;
    name = "romaingrx";
    hashedPassword =
      "$6$mvpn1IKZsbCfv5wU$aQxRPWCNlzkeln1KJBq5amMvWpo6mYk.q7ji8dMby6mRm/IY4SLWqDdFQSW7w0g0VRmxUEd1rPna.PggJV0is0";
  };
}
