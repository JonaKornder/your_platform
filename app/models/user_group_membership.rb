
# In this application, all user group memberships, i.e. memberships of a certain
# user in a certail group, are stored implicitly in the dag_links table in order
# to minimize the number of database queries that are necessary to find out
# whether a user is member in a certain group through an indirect membership.
#
# This class allows abstract access to the UserGroupMemberships themselves,
# and to their properties like since when the membership exists.
class UserGroupMembership < DagLink

  attr_accessible :created_at, :deleted_at


  # Creation Class Method
  # ====================================================================================================

  # Create a membership of the `u` in the group `g`.
  #
  #    membership = UserGroupMembership.create( user: u, group: g )
  #
  def self.create( params )
    if UserGroupMembership.find_by( params ).present?
      raise 'Membership already exists: id = ' + UserGroupMembership.find_by( params ).id.to_s
    else
      raise "Could not create UserGroupMembership without user." unless params[ :user ]
      raise "Could not create UserGroupMembership without group." unless params[ :group ]
      user = params[ :user ]
      group = params[ :group ]
      user.parent_groups << group
      return UserGroupMembership.find_by( user: user, group: group )
    end
  end


  # Finder Class Methods
  # ====================================================================================================

  # Find all memberships that match the given parameters.
  # This method returns an ActiveRecord::Relation object, which means that the result can
  # be chained with scope methods.
  #
  #     memberships = UserGroupMembership.find_all_by( user: u )
  #     memberships = UserGroupMembership.find_all_by( group: g )
  #     memberships = UserGroupMembership.find_all_by( user: u, group: g ).now
  #     memberships = UserGroupMembership.find_all_by( user: u, group: g ).in_the_past
  #     memberships = UserGroupMembership.find_all_by( user: u, group: g ).now_and_in_the_past
  #     memberships = UserGroupMembership.find_all_by( user: u, group: g ).with_deleted  # same as .now_and_in_the_past
  #
  def self.find_all_by( params )
    user = params[ :user ]
    group = params[ :group ]
    links = UserGroupMembership
      .where( :descendant_type => "User" )
      .where( :ancestor_type => "Group" )
    links = links.where( :descendant_id => user.id ) if user
    links = links.where( :ancestor_id => group.id ) if group
    links = links.order( :created_at )
    return links
  end

  # Find the first membership that matches the parameters `params`.
  # This is a shortcut for `find_all_by( params ).first`.
  # Use this, if you only expect one membership to be found.
  #
  def self.find_by( params )
    self.find_all_by( params ).limit( 1 ).first
  end

  def self.find_all_by_user( user )
    self.find_all_by( user: user )
  end

  def self.find_all_by_group( group )
    self.find_all_by( group: group )
  end

  def self.find_by_user_and_group( user, group )
    self.find_by( user: user, group: group )
  end

  def self.find_all_by_user_and_group( user, group )
    self.find_all_by( user: user, group: group )
  end


  # Temporal Scope Methods
  # ====================================================================================================

  # Return the same membership as it was/is/will be at a certain point in time.
  # This can be used, for example to get one or more memberships at a certain point in time.
  # This is a scope method and can be chained to other ActiveRecord::Relation objects.
  #
  #    UserGroupMembership.find_all_by_user( u ).at_time( 1.hour.ago )
  #    UserGroupMembership.find_all_by_user( u ).at_time( 1.hour.ago ).count
  #    UserGroupMembership.find_by( user: u, group: g ).at_time( Time.current + 30.minutes ).present?
  #
  def at_time( time )
    memberships = UserGroupMembership
      .find_all_by( user: self.user, group: self.group )
      .with_deleted
      .where( "created_at < ?", time ).where( "deleted_at IS NULL OR deleted_at > ?", time )
    return nil if memberships.count == 0
    return memberships.first if memberships.count == 1
    return memberships
  end


  # Save and Destroy Methods
  # ====================================================================================================

  # Save the current membership and auto-save also the direct memberships
  # associated with the current (maybe indirect) membership.
  #
  def save
    unless direct?
      first_created_direct_membership.save if first_created_direct_membership
      last_deleted_direct_membership.save if last_deleted_direct_membership
    end
    super
  end

  # Destroy this membership, but reload the dataset from the database in order to get access
  # to the datetime of deletion.
  # 
  def destroy
    if self.destroyable?
      super
      self.reload
    else
      raise "membership not destroyable."
    end
  end


  # Status Instance Methods
  # ====================================================================================================   

  def deleted?
    return true if not UserGroupMembership.find_by( user: self.user, group: self.group )
  end


  # Timestamps Methods: Beginning and end of a membership
  # ====================================================================================================

  def created_at
    return read_attribute( :created_at ) if direct?
    first_created_direct_membership.created_at if first_created_direct_membership
  end
  def created_at=( created_at )
    return super( created_at ) if direct?
    first_created_direct_membership.created_at = created_at if first_created_direct_membership
  end

  def deleted_at
    return read_attribute( :deleted_at ) if direct?
    last_deleted_direct_membership.deleted_at if last_deleted_direct_membership
  end
  def deleted_at=( deleted_at )
    return super( deleted_at ) if direct?
    last_deleted_direct_membership.deleted_at = deleted_at if last_deleted_direct_membership
  end






  def user
    self.descendant
  end

  def group
    self.ancestor
  end






  # Returns the direct membership corresponding to this membership (self).
  # For clarification, consider the following structure:
  #   group1
  #     |---- group2
  #             |---- user
  #
  # user is not a direct member of group1, but an indirect member. But user is a direct member of group2.
  # Thus, this method, called on a membership of user and group1 will return the membership between
  # user and group2.
  #
  #     UserGroupMembership.find( user: user, group: group1 ).direct_membership ==
  #       UserGroupMembership.find( user: user, group: group2 )
  #



  def direct_memberships
    descendant_groups_of_self_group = self.group.descendant_groups
    descendant_group_ids_of_self_group = descendant_groups_of_self_group.collect { |group| group.id }
    group_ids = descendant_group_ids_of_self_group + [ self.group.id ]
    memberships = UserGroupMembership
      .find_all_by_user( self.user )
      .where( :direct => true )
      .where( :ancestor_id => group_ids )
    memberships = memberships.with_deleted if self.read_attribute( :deleted_at )
    memberships = memberships.order( :created_at )
    memberships
  end

  def direct_groups
    direct_memberships.collect { |membership| membership.group }
  end

  #
  #     A1                                                      A2
  #     | indirect membership                                   |
  #
  #     b1                          b2
  #     | direct membership 1       |
  #                                 | direct membership 2       |
  #                                 c1                          c2
  #
  # A1 <--> b1
  # A2 <--> c2
  # b2 <--> c1
  #

  def first_created_direct_membership
    unless @first_created_direct_membership
      @first_created_direct_membership = direct_memberships.reorder( :created_at ).first
    end
    @first_created_direct_membership
  end

  def last_deleted_direct_membership
    unless @last_deleted_direct_membership
      @last_deleted_direct_membership = direct_memberships.reorder( :deleted_at ).last
    end
    @last_deleted_direct_membership
  end





  #
  #
  #  # returns an array of memberships that represent the direct memberships of the given user (of self), i.e.
  #  # in the subgroups (of self). For example, this is used in the corporate vita.
  #  def direct_memberships_now_and_in_the_past
  #    if self == devisor_membership
  #      # for direct memberships, the direct memberships contain only the membership itself.
  #      return self
  #    else
  #      sub_groups = self.group.descendant_groups
  #      sub_group_ids = sub_groups.collect { |group| group.id }
  #      links = user
  #        .links_as_child
  #        .now_and_in_the_past
  #        .where( "ancestor_type = ?", "Group" )
  #        .where( :direct => true )
  #        .find_all_by_ancestor_id( sub_group_ids )
  #      memberships = links.collect do |link|
  #        UserGroupMembership.find( user: link.descendant, group: link.ancestor )
  #      end
  #      return memberships
  #    end
  #  end
  #

  def direct_memberships_now_and_in_the_past
    self.direct_memberships.now_and_in_the_past
  end

  #
  #  private
  #
  #  def devisor_attr( attr_name, params = nil )
  ##    raise "No DagLink associated." unless dag_link
  #    if devisor_membership
  #      return devisor_membership.send( attr_name ) if params.nil?
  #      devisor_membership.send( attr_name, params )
  #    end
  #  end

end

