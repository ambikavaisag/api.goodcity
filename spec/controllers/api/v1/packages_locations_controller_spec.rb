require "rails_helper"

RSpec.describe Api::V1::PackagesLocationsController, type: :controller do
  let(:packages_location) { create :packages_location }
  let(:user) { create(:user_with_token, :reviewer) }


  subject { JSON.parse(response.body) }

  describe "GET packages for Item" do
   before { generate_and_set_token(user) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized packages_locations for provided package id" do
      package = create :package
      3.times{ create :packages_location, package_id: package.id }
      get :index, search_by_package_id: package.id
      body = JSON.parse(response.body)
      expect( body["packages_locations"].size ).to eq(3)
    end
  end
end