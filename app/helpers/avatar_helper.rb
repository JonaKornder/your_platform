module AvatarHelper

  # This returns the html code for an avatar image of the given user.
  # 
  # * If the user has uploaded an avatar image using refile, this one is used.
  # * Next, the gravatar of the user's email is tried.
  # * The fallback image is defined in the `user_avatar_default_url` method.
  #
  def user_avatar(user, options = {})
    options[:size] ||= 36
    content_tag(:span, class: 'avatar') do
      if user.avatar_id?
        image_tag Refile.attachment_url(user, :avatar, :fill, options[:size], options[:size]), class: 'img-rounded'
      else
        user_gravatar(user, options)
      end
    end.html_safe
  end

  # This returns the html code for an avatar image of the given user.
  # This image is just provided by gravatar.
  #
  def user_gravatar(user, options = {})

    email = user.email
    options[:size] ||= 36
    options[:gravatar] ||= {}
    options[:gravatar][:size] ||= options[:size]
    #options[:alt] ||= "Gravatar: #{email}"
    #options[:title] ||= options[:alt]
    options['data-toggle'] ||= 'tooltip'
    options[:gravatar][:secure] = true
    
    options[:class] ||= ""
    options[:class] += " img-rounded"

    # Default Url
    # Instead of 
    #     URI.join(root_url, asset_path('avatar_128.png'))
    # we use a string at the moment, in order to make this work
    # locally as well. Otherwise a 'http://localhost/...' would be 
    # submitted to gravatar as source of the default image.
    # 
    options[:gravatar][:default] ||= user_avatar_default_url
    
    gravatar_image_tag(email, options)
  end
  
  def user_avatar_url(user, options = {})
    options[:size] ||= 36
    if user.avatar_id?
      Refile.attachment_url(user, :avatar, :fill, options[:size], options[:size])
    else
      user_gravatar_url(user, options)
    end
  end
  
  def user_gravatar_url(user, options = {})
    options[:gravatar] ||= {}
    options[:gravatar][:default] ||= user_avatar_default_url
    options[:gravatar][:size] ||= 36
    options[:gravatar][:secure] = true
    gravatar_image_url(user.email, options)
  end
  
  def user_avatar_default_url
    "https://wingolfsplattform.org/assets/avatar_128.png"
  end
  
end
