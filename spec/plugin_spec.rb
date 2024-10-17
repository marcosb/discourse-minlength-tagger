# frozen_string_literal: true

require "rails_helper"

describe "discourse-minlength-tagger" do # rubocop:disable RSpec/DescribeClass
  fab!(:topic)

  before {
    SiteSetting.minlength_tag = "testing_minlength"
    SiteSetting.minlength_chars = 10
  }

  it "tags a topic when it is a minimum size" do
    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("testing_minlength")
    expect(topic.first_post.post_revisions.size).to eq(0)
  end

  it "does not tag a topic when staff user replies" do
    PostCreator.create!(Fabricate(:admin), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).not_to contain_exactly("testing_minlength")
  end

  it "does not tag a topic when it is not large enough" do
    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is")

    expect(topic.tags.reload.pluck(:name)).not_to contain_exactly("testing_minlength")
  end

  it "tags a topic created by non-staff user" do
    post =
      PostCreator.create!(
        Fabricate(:user, refresh_auto_groups: true),
        title: "this is a test topic",
        raw: "this is a test reply",
      )

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("testing_minlength")
  end

  it "does not remove existent tags" do
    DiscourseTagging.tag_topic_by_names(topic, Discourse.system_user.guardian, %w[hello world])

    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("hello", "world", "testing_minlength")
  end
end
