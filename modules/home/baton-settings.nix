# This setup's settings for the sessions that Baton starts on this machine.
# Each file of config/baton is one concern, linked on its own into
# ~/.config/baton, so that another module can add a file of its own there.
_: {
  xdg.configFile."baton" = {
    source = ../../config/baton;
    recursive = true;
  };
}
