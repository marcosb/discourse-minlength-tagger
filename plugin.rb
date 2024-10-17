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

    ActiveRecord::Base.transaction do
      topic = post.topic
      if (firstPost = self.ordered_posts.first)
        if (firstPost.raw.size > SiteSetting.minlength_chars) && !topic.tags.pluck(:id).include?(tag.id)
          topic.tags.reload
          topic.tags << tag
          topic.save
        end
      end
    end
  end
end
