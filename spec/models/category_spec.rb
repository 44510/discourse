require 'spec_helper'

describe Category do

  it { should validate_presence_of :name }

  it 'validates uniqueness of name' do
    Fabricate(:category)
    should validate_uniqueness_of(:name)
  end

  it { should belong_to :topic }
  it { should belong_to :user }

  it { should have_many :topics }
  it { should have_many :category_featured_topics }
  it { should have_many :featured_topics }

  describe "uncategorized name" do

    let(:category) { Fabricate.build(:category, name: SiteSetting.uncategorized_name) }

    it "is invalid to create a category with the reserved name" do
      category.should_not be_valid  
    end
    
  end

  describe "short name" do
    let!(:category) { Fabricate(:category, name: 'xx') }

    it "creates the category" do
      category.should be_present
    end

    it 'has one topic' do
      Topic.where(category_id: category.id).count.should == 1
    end

  end

  describe 'caching' do

    it "invalidates the site cache on creation" do
      Site.expects(:invalidate_cache).once
      Fabricate(:category)
    end

    it "invalidates the site cache on update" do
      cat = Fabricate(:category)
      Site.expects(:invalidate_cache).once
      cat.update_attributes(name: 'new name')
    end

    it "invalidates the site cache on destroy" do
      cat = Fabricate(:category)
      Site.expects(:invalidate_cache).once
      cat.destroy
    end
  end

  describe 'after create' do

    before do
      @category = Fabricate(:category)
      @topic = @category.topic
    end

    it 'creates a slug' do
      @category.slug.should == 'amazing-category'
    end

    it 'has one topic' do
      Topic.where(category_id: @category).count.should == 1
    end

    it 'creates a topic post' do
      @topic.should be_present      
    end

    it 'points back to itself' do
      @topic.category.should == @category
    end

    it 'is an invisible topic' do
      @topic.should_not be_visible
    end

    it 'is an undeletable topic' do
      Guardian.new(@category.user).can_delete?(@topic).should be_false
    end

    it 'should have one post' do
      @topic.posts.count.should == 1
    end

    it 'should have an excerpt' do
      @category.excerpt.should be_present
    end

    it 'should have a topic url' do
      @category.topic_url.should be_present
    end

    describe "trying to change the category topic's category" do

      before do
        @new_cat = Fabricate(:category, name: '2nd Category', user: @category.user)
        @topic.change_category(@new_cat.name)
        @topic.reload
        @category.reload
      end

      it 'still has 0 forum topics' do
        @category.topic_count.should == 0
      end

      it "didn't change the category" do
        @topic.category.should == @category
      end

      it "didn't change the category's forum topic" do
        @category.topic.should == @topic
      end
    end
  end

  describe 'destroy' do

    before do
      @category = Fabricate(:category)
      @category_id = @category.id
      @topic_id = @category.topic_id
      @category.destroy
    end

    it 'deletes the category' do
      Category.exists?(id: @category_id).should be_false
    end

    it 'deletes the forum topic' do
      Topic.exists?(id: @topic_id).should be_false
    end

  end

  describe 'update_stats' do

    # We're going to test with one topic. That's enough for stats!
    before do
      @category = Fabricate(:category)

      # Create a non-invisible category to make sure count is 1
      @topic = Fabricate(:topic, user: @category.user, category: @category)     

      Category.update_stats
      @category.reload
    end

    it 'updates topics_week' do
      @category.topics_week.should == 1
    end

    it 'updates topics_month' do
      @category.topics_month.should == 1
    end

    it 'updates topics_year' do
      @category.topics_year.should == 1
    end

  end

end

