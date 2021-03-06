# This module contains all the Avatar-related methods of a User.
# The avatar feature is done using the refile gem.
#
# Have a look at:
# * https://www.gorails.com/episodes/file-uploads-with-refile
# * https://github.com/refile/refile
#
concern :UserAvatar do
  
  included do
    attachment :avatar, type: :image
    attr_accessible :avatar, :remove_avatar if defined? attr_accessible
  end

end