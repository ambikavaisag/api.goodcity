require 'rails_helper'

describe PushUpdates do
  let(:user) {create :user}
  let(:offer) { create :offer }
  let(:service) { PushService.new }
  
  before(:each) do
    User.current_user = user
    allow(offer).to receive(:service).and_return(service)
  end
  
  it 'update - changed properties are included' do
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data|
      expect(data[:item]['Offer'].to_json).to include("\"id\":#{offer.id},\"notes\":\"New test note\"")
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
  end

  it 'update - foreign key property changes are handled' do
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data|
      expect(data[:item]['Offer'].to_json).to include("\"id\":#{offer.id},\"reviewed_by_id\":#{user.id}")
    end
    offer.reviewed_by_id = user.id
    offer.update_client_store(:update)
  end

  it 'all classes that include PushUpdates should have offer property' do
    Rails.application.eager_load!
    include_private = true
    ActiveRecord::Base.descendants.find_all{|m| m.ancestors.include?(PushUpdates)}.each do |m|
      expect(m.new.respond_to?(:offer, include_private)).to be(true), "#{m.name} is missing offer property"
    end
  end

  it 'should not include private reviewer details when sending to donor' do
    reviewer = create :user, :reviewer
    User.current_user = reviewer
    json_checked = false
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data|
      unless (channel.include?("reviewer") || channel.include?("user_#{reviewer.id}"))
        expect(data[:sender].attributes.keys).to_not include(:mobile)
        # expect(data[:sender].attributes.keys).to_not include(:email)
        json_checked = true
      end
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
    expect(json_checked).to eq(true)
  end

  it 'should include private donor details when sending to reviewer' do
    json_checked = false
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data|
      if channel.include?("reviewer") || channel.exclude?("user_#{offer.created_by_id}")
        expect(data[:sender].attributes.keys).to include(:mobile)
        expect(data[:sender].attributes.keys).to include(:email)
        json_checked = true
      end
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
    expect(json_checked).to eq(true)
  end

  context 'order push_updates' do
    let(:user) {create :user}
    let(:order) { create :order }
    let(:service) { PushService.new }
    
    before(:each) do
      User.current_user = user
      allow(order).to receive(:service).and_return(service)
    end
  
    it 'should not send order updates to other browse users' do
      expect(service).to receive(:send_update_store) do |channel, data|
        expect(channel).to_not include(Channel::BROWSE_CHANNEL)
      end
      order.update_client_store(:update)
    end

  end

end
