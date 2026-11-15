# frozen_string_literal: true

require "rails_helper"

RSpec.describe BeansApp::API::V1::Orders, type: :request do
  describe "POST Order" do
    let(:site_config) { MagicBean::SiteConfig.default_config || create(:site_config) }
    let(:payment_setting) { create(:payment_setting) }
    let(:user) { create(:user) }
    let(:join_user) { create(:user) }
    let(:item) { create(:item) }
    let(:item2) { create(:item) }
    let(:self_pick_up) { create(:self_pick_up) }
    let(:member) { create(:member) }
    let(:request_data) do
      {
        stock_keeping_unit_id: item.stock_keeping_units.last.id,
        quantity: 1,
        delivery_type: "self_pick",
        receiver_first_name: "jayce",
        receiver_last_name: "huang",
        self_pick_up_id: self_pick_up.id,
        receiver_mobile: "61123456789",
        cost_integral: 500,
        is_preview: false,
        delivery_date: Date.current.tomorrow,
        prefer_time: self_pick_up.time_period.first
      }
    end
    let(:authorization) { JsonWebToken.encode({ certificate: user.ebest_platform_unionid }) }
    let(:join_authorization) { JsonWebToken.encode({ certificate: join_user.ebest_platform_unionid }) }
    let(:request_path) { "/app/api/v1/orders/direct_buy" }
    let(:groupon_request_path) { "/app/api/v1/orders/groupon_buy" }
    let(:create_order_by_shopping_cart_path) { "/app/api/v1/orders" }
    let(:shopping_cart_items_request_path) { "/app/api/v1/shopping_cart_items" }
    let(:after_sale_request_path) { "/app/api/v1/after_sales" }
    let(:gift_card_template)  { create(:gift_card_template, :with_1000_denominations) }
    let(:gift_card_template2)  { create(:gift_card_template, :with_2500_denominations) }
    let(:coupon_template1)  { create(:coupon_template, :with_500_denominations) }
    let(:coupon_template2)  { create(:coupon_template, :with_1500_denominations) }
    let(:groupon_activity) { create(:groupon_activity) }

    before do
      site_config
      payment_setting
      Omipay::Api.rate || Omipay::Api.set_rate
      user.member = member
    end

    context "create order by shopping cart" do

      before do
        # 添加到购物车
        item.stock_keeping_units.first(2).each do |sku|
          post(
            shopping_cart_items_request_path,
            params: { stock_keeping_unit_id: sku.id, quantity: 1 },
            headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path }
          )
        end

        expect(response).to have_http_status(:success)

        request_data.delete(:stock_keeping_unit_id)
        request_data.delete(:quantity)
        request_data[:shopping_cart_item_ids] = user.shopping_cart.shopping_cart_item_ids.join(",")
      end

      it "created successfully" do
        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }
        expect(response).to have_http_status(:success)
      end

      it "shoult not use category limit coupon" do
        coupon_template1.update(category_ids: [item2.category.parent_id])
        coupon = coupon_template1.generate_coupons.first
        coupon.assign_to_user(user)
        request_data[:coupon_code] = coupon.code
        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.coupon).to eq(nil)
      end

      it "use category limit coupon successfully " do
        coupon_template1.update(category_ids: [item.category.parent_id])
        coupon = coupon_template1.generate_coupons.first
        coupon.assign_to_user(user)
        request_data[:coupon_code] = coupon.code
        request_data.delete(:cost_integral)
        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.coupon).to eq(coupon)
        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent - order.gift_card_amount_in_cent)
        expect(order.coupon.denominations_in_cent).to eq(order.original_payment_in_cent - order.total_payment_in_cent)
      end

      it "order refund" do
        # 该订单总共22元(商品20 + 运费2), 将使用500积分，10元礼品卡
        gift_card_coupon = gift_card_template.gift_card_coupons.first
        request_data.merge!({ gift_card_pin_code: gift_card_coupon.pin_code, gift_card_coupon_code: gift_card_coupon.code, gift_card_amount_in_cent: 1000 })
        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.payment_in_cent).to eq(700)

        commweb_payment_path =  "/app/api/v1/orders/#{order.id}/request_commweb_payment"
        commweb_params = { card: { type: "vm", number: "4242424242424242", exp_year: Date.today.next_year.strftime("%y"), exp_month: 12, cvc: 123 }, email: nil }
        post commweb_payment_path, params: commweb_params, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: commweb_payment_path  }
        order.reload.deliver_and_generate_logistic("", fake: true)
        order.receive!

        post after_sale_request_path, params: { order_id: order.id, reason: "refund", after_sale_type: "refund", after_sales_order_items_attributes: [{ quantity: 1, order_item_id: order.order_items.order(id: :desc).first.id}] },
             headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: after_sale_request_path }
        after_sale1 = order.after_sales.order(id: :desc).first
        after_sale1.agree!
        # 两个商品价格一样，退款的时候每一项也都会均摊
        # 现金$7，运费$2, $5可退
        # 金币500，平均每个产品250
        # 礼品卡$10, 平均每个产品$5
        expect(after_sale1.return_integral_amount).to eq(250)
        expect(after_sale1.return_gift_card_amount_in_cent).to eq(500)
        expect(after_sale1.amount_in_cent).to eq(250)

        post after_sale_request_path, params: { order_id: order.id, reason: "refund", after_sale_type: "refund", after_sales_order_items_attributes: [{ quantity: 1, order_item_id: order.order_items.order(id: :desc).last.id}] },
             headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: after_sale_request_path }
        after_sale2 = order.after_sales.order(id: :desc).first
        expect(after_sale2.return_integral_amount).to eq(250)
        expect(after_sale2.return_gift_card_amount_in_cent).to eq(500)
        expect(after_sale2.amount_in_cent).to eq(250)
      end

      it "order refund with gift card" do
        # 该订单总共22元(商品20 + 运费2), 将21元礼品卡, $1现金
        gift_card_coupon = gift_card_template2.gift_card_coupons.first
        request_data.merge!({ gift_card_pin_code: gift_card_coupon.pin_code, gift_card_coupon_code: gift_card_coupon.code, gift_card_amount_in_cent: 2100 })
        # 不使用金币
        request_data.delete(:cost_integral)
        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.payment_in_cent).to eq(100)

        commweb_payment_path =  "/app/api/v1/orders/#{order.id}/request_commweb_payment"
        commweb_params = { card: { type: "vm", number: "4242424242424242", exp_year: Date.today.next_year.strftime("%y"), exp_month: 12, cvc: 123 }, email: nil }
        post commweb_payment_path, params: commweb_params, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: commweb_payment_path  }
        order.reload.deliver_and_generate_logistic("", fake: true)
        order.receive!

        post after_sale_request_path, params: { order_id: order.id, reason: "refund", after_sale_type: "refund", after_sales_order_items_attributes: [{ quantity: 1, order_item_id: order.order_items.order(id: :desc).first.id}] },
             headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: after_sale_request_path }
        after_sale1 = order.after_sales.order(id: :desc).first
        after_sale1.agree!
        # 两个商品价格一样，退款的时候每一项也都会均摊
        # 现金$1，运费$2, 无现金可退
        # 礼品卡$21, 扣除$1运费，平均每个产品$10礼品卡
        expect(after_sale1.return_integral_amount).to eq(0)
        expect(after_sale1.return_gift_card_amount_in_cent).to eq(1000)
        expect(after_sale1.amount_in_cent).to eq(0)

        post after_sale_request_path, params: { order_id: order.id, reason: "refund", after_sale_type: "refund", after_sales_order_items_attributes: [{ quantity: 1, order_item_id: order.order_items.order(id: :desc).last.id}] },
             headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: after_sale_request_path }
        after_sale2 = order.after_sales.order(id: :desc).first
        expect(after_sale1.return_integral_amount).to eq(0)
        expect(after_sale1.return_gift_card_amount_in_cent).to eq(1000)
        expect(after_sale1.amount_in_cent).to eq(0)
      end

      it "order with promo code" do
        pct = create(:promo_code_template)
        promo_code = pct.generate_promo_codes.first
        expect(promo_code.used_count).to eq(0)
        request_data[:promo_code] = promo_code.code

        post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }

        expect(response).to have_http_status(:success)
        order = MagicBean::Order.find(JSON.parse(response.body)["id"])
        promo_code.reload
        expect(promo_code.orders.first).to eq(order)
        expect(promo_code.used_count).to eq(1)
        expect(order.order_items.select { |oi| oi.promo_code_id == promo_code.id }).to be_present
      end

      context "gift activity" do
        it "preview order" do
          gift_activity = create(:gift_activity)
          request_data[:is_preview] = true

          post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }

          expect(response).to have_http_status(:success)
          resp = JSON.parse(response.body)
          expect(resp.dig("order", "gift_activity")).to be_present
        end

        it "order" do
          gift_activity = create(:gift_activity)
          request_data[:gift_activity_id] = gift_activity.id
          request_data[:gift_sku_ids] = [gift_activity.rules.dig(0, "skus", 0, "sku_id")]

          post create_order_by_shopping_cart_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }

          expect(response).to have_http_status(:success)
        end
      end
    end

    context "create order with promo code" do
      it "direct buy" do
        item
        pct = create(:promo_code_template)
        promo_code = pct.generate_promo_codes.first
        expect(promo_code.used_count).to eq(0)
        request_data[:promo_code] = promo_code.code

        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }

        expect(response).to have_http_status(:success)
        order = MagicBean::Order.find(JSON.parse(response.body)["id"])
        promo_code.reload
        expect(promo_code.used_count).to eq(1)
        expect(promo_code.orders.first).to eq(order)
        expect(order.order_items.select { |oi| oi.promo_code_id == promo_code.id }).to be_present
      end
    end

    context "create order with gift activity" do
      it "direct buy" do
        item
        gift_activity = create(:gift_activity)
        request_data[:gift_activity_id] = gift_activity.id
        request_data[:gift_sku_ids] = [gift_activity.rules.dig(0, "skus", 0, "sku_id")]

        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }

        expect(response).to have_http_status(:success)
      end

      it "preview direct buy" do
        item
        gift_activity = create(:gift_activity)
        request_data[:is_preview] = true

        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, "Ebest-Channel": "app" }

        expect(response).to have_http_status(:success)
        resp = JSON.parse(response.body)
        expect(resp.dig("order", "gift_activity")).to be_present
      end
    end

    context "create order with cost integral" do

      context "and integral_deducted_config was zero" do
        before do
          sc = MagicBean::SiteConfig.default_config
          sc["integral_rules"]["max_integral_in_one_order"] = 0
          sc.save
          sc.reload
        end

        it "could not cost integral" do
          post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
          order = user.orders.order(created_at: :desc).last
          expect(order.cost_integral).to eq(0)
        end
      end

      it "calculate max cost integral" do
        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        max_cost_integral = [
          MagicBean::SiteConfig.default_config&.max_integral_in_one_order,
          (order.total_payment_in_cent - order.payment_in_cent) / 100 * order.integral_deducted_from_one_yuan,
          user.member.available_integral
        ].min

        expect(order.cost_integral).to eq(max_cost_integral)
      end

      it "calculate payment amount" do
        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last

        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent)
      end
    end

    context "create order with gift card" do
      before do
        gift_card_coupon = gift_card_template.gift_card_coupons.first
        request_data.merge!({ gift_card_pin_code: gift_card_coupon.pin_code, gift_card_coupon_code: gift_card_coupon.code, gift_card_amount_in_cent: 100 })
      end

      it "wrong gift card code" do
        request_data[:gift_card_coupon_code] = "test123"
        res = post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        expect(res).to eq(400)
      end

      it "wrong gift card amount" do
        request_data[:gift_card_amount_in_cent] = 1100
        res = post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        expect(res).to eq(400)
      end

      it "calculate payment amount" do
        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last

        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent - order.gift_card_amount_in_cent)
      end
    end

    context "create order with coupon code" do
      it "calculate payment amount" do
        coupon = coupon_template1.generate_coupons.first
        coupon.assign_to_user(user)
        request_data[:coupon_code] = coupon.code
        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent - order.gift_card_amount_in_cent)
        expect(order.coupon.denominations_in_cent).to eq(order.original_payment_in_cent - order.total_payment_in_cent)
      end

      it "coupon amount much more than payment amount" do
        coupon = coupon_template2.generate_coupons.first
        coupon.assign_to_user(user)
        request_data[:coupon_code] = coupon.code

        post request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent - order.gift_card_amount_in_cent)
        expect(order.coupon.denominations_in_cent).to be > (order.original_payment_in_cent - order.total_payment_in_cent)
        # 优先使用优惠券再使用积分，优惠券金额够大时，不使用积分
        expect(order.cost_integral).to eq(0)
      end
    end

    context "create groupon order" do
      before do
        request_data.merge!({ groupon_activity_id: groupon_activity.id })
      end

      it "calculate payment amount" do
        res = post groupon_request_path, params: request_data, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: groupon_request_path, "Ebest-Channel": "app" }
        order = user.orders.order(created_at: :desc).last
        expect(order.order_items.first.real_price_in_cent).to eq(groupon_activity.price_in_cent)
        expect(order.payment_in_cent).to eq(order.total_payment_in_cent - order.cost_integral_amount_in_cent - order.gift_card_amount_in_cent)
      end

      it "join groupon" do
        gift_card_coupon = gift_card_template.gift_card_coupons.first
        with_gift_card_params = request_data.merge({ gift_card_pin_code: gift_card_coupon.pin_code, gift_card_coupon_code: gift_card_coupon.code, gift_card_amount_in_cent: 1000 })

        post groupon_request_path, params: with_gift_card_params, headers: { HTTP_AUTHORIZATION: authorization, REQUEST_PATH: groupon_request_path, "Ebest-Channel": "app" }
        order = user.groupon_orders.order(created_at: :desc).last

        request_data[:groupon_id] = order.groupon.id
        post groupon_request_path, params: request_data, headers: { HTTP_AUTHORIZATION: join_authorization, REQUEST_PATH: groupon_request_path, "Ebest-Channel": "app" }
        join_order = join_user.groupon_orders.order(created_at: :desc).last
        expect(join_order.order_items.first.real_price_in_cent).to eq(groupon_activity.price_in_cent)
        expect(join_order.payment_in_cent).to eq(join_order.total_payment_in_cent - join_order.cost_integral_amount_in_cent - join_order.gift_card_amount_in_cent)
      end
    end
  end
end
