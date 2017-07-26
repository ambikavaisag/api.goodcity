require 'rails_helper'

RSpec.describe PackagesLocation, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :location }
    it { is_expected.to belong_to :package }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:location_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
  end

  describe 'Validations' do
    let!(:package) { create :package, :with_inventory_number, state: "received" }
    let!(:packages_location) { build :packages_location, package: package, quantity: 5}
    context 'validates quantity: ' do
      let!(:package) { create :package, :received }
      let!(:packages_location) { package.packages_locations.first}

      it 'quantity can not be less than 0' do
        packages_location.quantity = -1
        expect(packages_location.valid?).to be(false)
      end

      it 'quantity can not be greater than package.received_quantity' do
        packages_location.quantity = package.quantity+rand(1..10)
        expect(packages_location.valid?).to be(false)
      end

      it  'quantity can be less than package.received_quantity' do
        packages_location.quantity = package.quantity-rand(1..3)
        expect(packages_location.valid?).to be(true)
      end

      it  'quantity can be equal package.received_quantity' do
        packages_location.quantity = package.received_quantity
        expect(packages_location.valid?).to be(true)
      end
    end

    context 'validates package ' do
      it "should have inventory_number" do
        expect(packages_location.save).to be(true)
      end

      it "inventory_number cannot be nil" do
        package.update(inventory_number: nil)
        expect(packages_location.save).to be(false)
      end
    end

    context 'validates package ' do
      it "should be in received state" do
        expect(packages_location.save).to be(true)
      end

      it "is not in received state" do
        package.update(state: "missing")
        expect(packages_location.save).to be(false)
      end
    end

  end

  describe '#update_quantity' do
    it 'should update quantity' do
      package = create :package, :received
      packages_location = package.packages_locations.first
      new_quantity = rand(3)+2
      expect {
        packages_location.update(quantity: new_quantity)

      }.to change(packages_location, :quantity).from(packages_location.quantity).to(new_quantity)
    end
  end
end
