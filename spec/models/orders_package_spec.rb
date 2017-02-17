require 'rails_helper'

RSpec.describe OrdersPackage, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :order }
    it { is_expected.to belong_to :package }
    it { is_expected.to belong_to(:updated_by).class_name('User') }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:sent_on).of_type(:datetime)}
  end

  describe "update_state_to_designated" do
    it "set state='designated'"do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_state_to_designated
      expect(@orders_package.state).to match("designated")
    end
  end

  describe "update_quantity" do
    it "Updates orders_packages quantity" do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_quantity
      expect(@orders_package.quantity).to match(@orders_package.package.quantity)
    end
  end

  describe "state" do
    let!(:orders_package) { create :orders_package, state: 'requested' }

    describe '#reject' do
      it 'changes state from requested to cancelled' do
        expect{
          orders_package.reject
        }.to change(orders_package, :state).to('cancelled')
      end
    end

    describe '#designate' do
      it 'changes state from requested to designated' do
        expect{
          orders_package.designate
        }.to change(orders_package, :state).to('designated')
      end
    end
  end

  describe '#update_designation' do
    let!(:orders_package) { create :orders_package }
    let!(:order) { create :order }

    it 'updates orders_package to provided order_id' do
      expect{
        orders_package.update_designation(order.id)
      }.to change(orders_package, :order_id).to(order.id)
    end
  end

  describe '#update_partially_designated_item' do
    let!(:package) { create :package, quantity: 10 }

    it 'adds package quantity to orders_package quantity' do
      orders_package = build :orders_package
      total_qty = orders_package.quantity + package.quantity
      expect{
        orders_package.update_partially_designated_item(package)
      }.to change(orders_package, :quantity).to(total_qty)
    end

    it "updates state of orders_package to designated if state is 'cancelled'" do
      orders_package = build :orders_package, state: 'cancelled'
      expect{
        orders_package.update_partially_designated_item(package)
      }.to change(orders_package, :state).to('designated')
    end

    it 'do not update state of orders_package if state is designated' do
      orders_package = create :orders_package, state: 'designated'
      existing_state = orders_package.state
      orders_package.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end

    it 'do not update state of orders_package if state is received' do
      orders_package = create :orders_package, state: 'received'
      existing_state = orders_package.state
      orders_package.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end

    it 'do not update state of orders_package if state is dispatched' do
      orders_package = create :orders_package, state: 'dispatched'
      existing_state = orders_package.state
      orders_package.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end
  end

  describe '#dispatch_orders_package' do
    let!(:orders_package) { create :orders_package, state: 'designated' }
    let!(:dispatched_location) { create :location,  building: "Dispatched" }

    it "sets today's date for sent_on column" do
      todays_date = Date.today
      orders_package.dispatch_orders_package
      expect(orders_package.reload.sent_on.to_date).to eq todays_date
    end

    it 'updates state to dispatched' do
      expect{
        orders_package.dispatch_orders_package
        }.to change(orders_package, :state).to eq 'dispatched'
    end

    it 'adds dispatched location for associate package' do
      orders_package.dispatch_orders_package
      expect(orders_package.package.reload.locations).to include(dispatched_location)
    end
  end

  describe '.update_orders_package_state' do
    let!(:orders_package) { create :orders_package, state: 'requested', quantity: 10 }

    context 'when total_qty is zero' do
      total_qty = 0

      it 'updates quantity with total_qty' do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :quantity).to(0)
      end

      it "updates state to 'cancelled'" do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :state).to('cancelled')
      end
    end

    context 'when total_qty is not zero' do
      total_qty = 12

      it 'updates quantity with total_qty' do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :quantity).to(total_qty)
      end

      it "updates state to 'designated'" do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :state).to('designated')
      end
    end
  end

  describe '.add_partially_designated_item' do
    let!(:order) { create :order }
    let!(:package) { create :package, quantity: 20, received_quantity: 20 }

    it 'creates orders package with provided order_id, package_id, quantity' do
      package_params = { order_id: order.id, package_id: package.id, quantity: 10 }

      expect{
        OrdersPackage.add_partially_designated_item(package_params)
      }.to change(OrdersPackage, :count).by(1)
      expect(OrdersPackage.last.order_id).to eq(package_params[:order_id])
      expect(OrdersPackage.last.package_id).to eq(package_params[:package_id])
      expect(OrdersPackage.last.quantity).to eq(package_params[:quantity])
    end
  end

  describe '#undispatch_orders_package' do
    let!(:orders_package) { create :orders_package, :with_state_requested, sent_on: Date.today }

    it 'sets state as designated' do
      expect{
        orders_package.undispatch_orders_package
      }.to change(orders_package, :state).to('designated')
    end

    it 'sent_on to nil' do
      expect{
        orders_package.undispatch_orders_package
      }.to change(orders_package, :sent_on).to(nil)
    end
  end

  describe '#delete_unwanted_cancelled_packages' do
    let!(:order) { create :order }
    let!(:orders_package) { create :orders_package, :with_state_cancelled, order: order }

    it 'deletes unwanted records with provided order id and state cancelled' do
      expect{
        orders_package.delete_unwanted_cancelled_packages(order.id)
      }.to change(OrdersPackage, :count).by(-1)
    end
  end
end
