name             "tectonic_play"
maintainer       "Matt Parker"
maintainer_email "mparker17@536298.no-reply.drupal.org"
license          "GPL"
description      "Sets up a Vagrant development environment for the tectonic_play website project."
version          "0.0.1"

recipe           "tectonic_play", "tectonic_play website project."

%w{ubuntu}.each do |os|
  supports os
end
