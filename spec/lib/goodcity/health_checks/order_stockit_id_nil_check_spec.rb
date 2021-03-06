require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/order_stockit_id_nil_check'

context Goodcity::HealthChecks::OrderStockitIdNilCheck do

  subject { described_class.new }

  it { expect(subject.desc).to eql("Orders should contain a stockit_id reference.") }

  it "passes" do
    create :order, stockit_id: 123
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    create :order, stockit_id: nil
    subject.run
    expect(subject.passed?).to eql(false)
    expect(subject.message).to include("GoodCity Orders with nil stockit_id")
  end

end
