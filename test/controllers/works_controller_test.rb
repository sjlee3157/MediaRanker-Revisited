require 'test_helper'

describe WorksController do
  let(:id) { works(:poodr).id }
  let (:work_hash) {
    {
      work: {
       title: "Dragon Ladies: Asian American Feminists Breathe Fire",
       category: "book"
      }
    }
  }
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      get root_path
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      Work.where(category: "movie").destroy_all
      get root_path
      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.destroy_all
      get root_path
      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works" do
      get works_path
      must_respond_with :success
    end

    it "succeeds when there are no works" do
      Work.destroy_all
      get works_path
      must_respond_with :success
    end
  end

  describe "new" do
    it "succeeds" do
      get new_work_path
      must_respond_with :success
    end
  end

  describe "create" do
    it "creates a work with valid data for a real category" do
     expect {
       post works_path, params: work_hash
     }.must_change 'Work.count', 1

     must_respond_with :redirect
     must_redirect_to work_path(Work.last.id)

     expect(Work.last.title).must_equal work_hash[:work][:title]
     expect(Work.last.category).must_equal work_hash[:work][:category]

     expect(flash[:status]).must_equal :success
     expect(flash[:result_text]).must_equal "Successfully created #{work_hash[:work][:category].singularize} #{Work.last.id}"
    end

    it "renders bad_request and does not update the DB for bogus data" do
      work_hash[:work].delete(:title)

      # why does deleting :category result in a 500 internal server error
      # instead of :bad_request?
      expect {
        post works_path, params: work_hash
      }.wont_change 'Work.count'

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "Could not create #{work_hash[:work][:category].singularize}"
      assert_not_nil(flash[:messages])
    end

    it "renders 400 bad_request for bogus categories" do
      work_hash[:work][:category] = "500 meter dash"
      expect {
        post works_path, params: work_hash
      }.wont_change 'Work.count'

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "Could not create #{work_hash[:work][:category].singularize}"
      assert_not_nil(flash[:messages])

    end

  end

  describe "show" do
    it "succeeds for an extant work ID" do
      get work_path(id)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      id = -1
      get work_path(id)
      must_respond_with :not_found
    end
  end

  describe "edit" do
    it "succeeds for an extant work ID" do
      get edit_work_path(id)
      must_respond_with :success

    end

    it "renders 404 not_found for a bogus work ID" do
      id = -1
      get edit_work_path(id)
      must_respond_with :not_found
    end
  end

  describe "update" do
    it "succeeds for valid data and an extant work ID" do
      expect {
        patch work_path(id), params: work_hash
      }.wont_change 'Work.count'

      must_respond_with :redirect
      must_redirect_to work_path(id)

      expect(Work.find(id).title).must_equal work_hash[:work][:title]
      expect(Work.find(id).category).must_equal work_hash[:work][:category]

      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal  "Successfully updated #{work_hash[:work][:category].singularize} #{id}"
    end

    it "renders bad_request for bogus data" do
      work_hash[:work][:title] = nil
      expect {
        patch work_path(id), params: work_hash
      }.wont_change 'Work.count'
      must_respond_with :not_found

      expect(Work.find(id).title).must_equal works(:poodr).title
      expect(Work.find(id).category).must_equal works(:poodr).category

      expect(flash[:status]).must_equal :failure
      expect(flash[:result_text]).must_equal "Could not update #{work_hash[:work][:category].singularize}"
      assert_not_nil(flash[:messages])
    end

    it "renders 404 not_found for a bogus work ID" do
      id = -1
      expect {
        patch work_path(id), params: work_hash
      }.wont_change 'Work.count'
      must_respond_with :not_found

      assert_nil(flash[:status])
      assert_nil(flash[:result_text])
      assert_nil(flash[:messages])
    end
  end

  describe "destroy" do
    it "succeeds for an extant work ID" do
      expect{
        delete work_path(id)
      }.must_change 'Work.count', -1
      must_respond_with :redirect
      must_redirect_to root_path

      expect{Work.find(id)}.must_raise ActiveRecord::RecordNotFound

      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully destroyed #{works(:poodr).category.singularize} #{id}"
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do
      id = -1
      expect{
        delete work_path(id)
      }.wont_change 'Work.count'
      must_respond_with :not_found

      assert_nil(flash[:status])
      assert_nil(flash[:result_text])
    end
  end

  describe "upvote" do

    it "redirects to the work page if no user is logged in" do
      assert_nil(@login_user)
      expect {
        post upvote_path(id)
      }.wont_change 'Work.count'
      must_respond_with :redirect
      must_redirect_to work_path(id)

      expect(flash[:result_text]).must_equal "You must log in to do that"
      expect(flash[:status]).must_equal :failure
    end

    it "redirects to the work page after the user has logged out" do
      perform_logout
      expect {
        post upvote_path(id)
      }.wont_change 'Work.count'
      must_respond_with :redirect
      must_redirect_to work_path(id)

      expect(flash[:result_text]).must_equal "You must log in to do that"
      expect(flash[:status]).must_equal :failure
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      perform_login(users(:ada))
      expect {
        post upvote_path(id)
      }.wont_change 'Work.count'

      must_respond_with :redirect
      must_redirect_to work_path(id)

      expect(flash[:status]).must_equal :success
      expect(flash[:result_text]).must_equal "Successfully upvoted!"
    end

    it "redirects to the work page if the user has already voted for that work" do
      perform_login(users(:ada))
      2.times do
        expect {
          post upvote_path(id)
        }.wont_change 'Work.count'
      end

      must_respond_with :redirect
      must_redirect_to work_path(id)

      expect(flash[:result_text]).must_equal "Could not upvote"
      assert_not_nil(flash[:messages])
    end
  end
end
