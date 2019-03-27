class Designator
  attr_accessor :package, :params, :order_id, :orders_package

  def initialize(package, package_params)
    @package = package
    @params = package_params
    @order_id = package_params[:order_id].to_i
    @orders_package = @package.orders_packages.new
  end

  #checks if already designated before redesignating
  def designate_or_redesignate
    if designated?
      return designated_to_same_order? unless designated_to_same_order?&.errors.blank?
      redesignate
    end
    designate_to_goodcity_and_stockit
  end

  def designate
    @orders_package.order_id = @order_id
    @orders_package.quantity = quantity.to_i
    @orders_package.updated_by = User.current_user
    @orders_package.state = 'designated'
    @orders_package.save
    @orders_package
  end

  def undesignate(undesignate_package = nil) #undesignate_package params is passed from redesignate
    packages = undesignate_package ? undesignate_package : @params
    OrdersPackage.undesignate_partially_designated_item(packages)
    @package.undesignate_from_stockit_order
  end

  def designate_stockit_item
    @package.designate_to_stockit_order(@order_id_param)
  end

  def designated_to_same_order?
    orders_package = OrdersPackage.find_by_id(@params[:orders_package_id])
    orders_package.errors.add("package_id", "Already designated to this Order") if orders_package.try(:order_id) === @order_id
    return orders_package
  end

  private

  def designated?
    @params[:quantity].to_i.zero?
  end

  def quantity
    @params[:quantity].to_i.zero? ? @params[:received_quantity] : @params[:quantity]
  end

  def redesignate
    undesignate_package = {}
    @params[:quantity] = @params[:received_quantity]
    undesignate_package["0"] = @params
    undesignate(undesignate_package)
  end

  def designate_to_goodcity_and_stockit
    return designate if designate.errors
    designate_stockit_item
  end
end
