#
# This module contains the extensions of the Group model that concern officers groups. 
# 
# Note that the majority of the officers functionality is handled by the Structureable model,
# since officers groups can be also assigned to Pages etc. and not only to Groups.
#
# See: 
#   * app/models/structureable_mixins/roles.rb
#   * app/models/structureable_mixins/has_special_groups.rb
#
module GroupMixins::Officers

  extend ActiveSupport::Concern

  included do
  end
  
  # This method determines if the group has no subgroups other than the officers
  # special group. This is used to determine whether the group is a status group.
  # 
  def has_no_subgroups_other_than_the_officers_parent?
    #
    # TODO: Refactor this!
    #
    (self.child_groups - self.child_groups.where(name: ["Amtsträger", "officers"])).count == 0
    
    # (self.child_groups.count == 0) or
    #   ((self.child_groups.count == 1) and (self.child_groups.first.has_flag?(:officers_parent)))
  end
  
  # This method determines if the group is an officers group.
  #
  def is_officers_group?
    self.ancestor_groups.includes(:flags).each do |group|
      return true if group.has_flag? :officers_parent
    end
    return false
  end
  
  # This returns whether the group is special.
  # This means that the group is special, e.g.
  # an officers group
  def is_special_group?
    self.has_flag?( :officers_parent ) or
    self.ancestor_groups.select do |ancestor|
      ancestor.has_flag?(:officers_parent)
    end.any?
  end
  
  # This deletes the caches related to this group being an officers group.
  # Since officers do have rights on the group structure under the group
  # they are officers of, the cache deletion needs to be passed on to those
  # groups.
  #
  def delete_cache_for_officers_group
    if is_officers_group?
      dependent_groups = self.ancestor_groups.first.try(:ancestor_groups).try(:first).try(:descendant_groups) || []
      dependent_groups.select! { |group| not group.is_officers_group? } # to avoid infinite recursion
      dependent_groups.each { |group| group.delete_cache }
    end
  end

end
