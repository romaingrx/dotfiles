# This setup's settings for the sessions that Baton starts on this machine.
# ~/.config/baton is a link to config/baton, where each file is one concern:
# a new setting is a new file there, and it applies with no rebuild.
{ config, dotfilesPath, ... }:
{
  home.file.".config/baton".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/baton";
}
