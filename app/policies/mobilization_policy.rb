class MobilizationPolicy < ApplicationPolicy
  def permitted_attributes
    if create? || update?
      %i[
        name
        color_scheme
        google_analytics_code
        goal
        facebook_share_title
        facebook_share_description
        facebook_share_image
        twitter_share_text
        header_font
        body_font
        custom_domain
        slug
        community_id
        tag_list
        favicon
        status
        language
      ]
    else
      []
    end
  end

  def authenticated?
    user.present?
  end
end
