$(document).ready ->
  
  # In the user_group_memberships#index table,
  # this removes the tr when confirming membership deletion.
  #
  # The deletion itself is handled by rails:
  # remove_button helper.
  #
  $("table.memberships .remove_button").on 'confirm:complete', (e, answer)->
    if (answer)
      $(this).closest('tr').remove()