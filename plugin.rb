# frozen_string_literal: true

# name: discourse-minlength-tagger
# about: Add a "minlength" tag to every topic where non-staff post
# version: 0.1
# authors: Marcos Boyington

after_initialize do
  on(:post_created) do |post, _, user|
    next if SiteSetting.minlength_tag.blank?
    next if SiteSetting.minlength_chars == 0
    next if user.staff?
    next if post.topic.private_message?

    tag = Tag.find_or_create_by!(name: SiteSetting.minlength_tag)
    not_met_tag = (SiteSetting.minlength_not_met_tag.blank?) ? nil : Tag.find_or_create_by!(name: SiteSetting.minlength_not_met_tag)
    exclude_categories = SiteSetting.exclude_categories.present? ? SiteSetting.exclude_categories.split("|").map(&:to_i) : []

    next if (exclude_categories.include?(post.topic.category_id))

    ActiveRecord::Base.transaction do
      topic = post.topic

      if (firstPost = topic.ordered_posts.first)
        if (firstPost.raw.size > SiteSetting.minlength_chars)
          if (!topic.tags.pluck(:id).include?(tag.id))
            topic.tags.reload
            topic.tags << tag
            topic.save
          end
        elsif (not_met_tag && !topic.tags.pluck(:id).include?(not_met_tag.id))
          topic.tags.reload
          topic.tags << not_met_tag
          topic.save
        end
      end
    end
  end
end
