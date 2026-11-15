 # frozen_string_literal: true

module PageLinksConcern
  extend ActiveSupport::Concern

  FIXED_PAGES = {
    "首页": { link: "/pages/tabbar/home/home", app_link: { type: "home" }.to_json, name: "首页" },
    "我的": { link: "/pages/tabbar/mine/mine", app_link: { type: "mine" }.to_json, name: "我的" },
    "账号管理": { link: "", app_link: { type: "member" }.to_json, name: "账号管理" },
    "购物车": { link: "/pages/tabbar/shopping-cart/shopping-cart", app_link: { type: "shoppingCart" }.to_json, name: "购物车" },
    "全部商品列表": { link: "/pages/products/search/search", app_link: { type: "productSearch" }.to_json, name: "全部商品列表" },
    "分类列表": { link: "/pages/tabbar/category/category", app_link: { type: "category" }.to_json, name: "分类列表" },
    "点评/建议": { link: "/pages/feedback/feedback", app_link: { type: "page_feedback" }.to_json, name: "点评/建议" },
    "品牌馆": { link: "", app_link: { type: "brands" }.to_json, name: "品牌馆" },
    "签到活动": { link: "", app_link: { type: "signInActivity" }.to_json, name: "签到活动" },
    "留学生认证": { link: "", app_link: { type: "overseasStudentApplication" }.to_json, name: "留学生认证" },
    "拍卖列表": { link: "", app_link: { type: "auctionList" }.to_json, name: "拍卖列表" },
    # "当日达首页": { link: "", app_link: { type: "sameDayDeliveryHome" }.to_json, name: "当日达首页" },
    "跨境购首页": { link: "", app_link: { type: "aeDropShipperHome" }.to_json, name: "跨境购首页" },
    "表格产品列表": { link: "", app_link: { type: "formItemList" }.to_json, name: "表格产品列表" },
    "地区运费查询页": { link: "", app_link: { type: "deliveryAreas" }.to_json, name: "地区运费查询页" },
    "会员注册": { link: "/pages/vip/sign-in/sign-in", app_link: { type: "sign_in" }.to_json, name: "会员注册" },
    "会员邀请": { link: "", app_link: { type: "invite" }.to_json, name: "会员邀请" },
  }

  FIXED_PAGES_ARRAY = [
    { name: "首页", path: { link: "/pages/tabbar/home/home", app_link: { type: "home" }.to_json }},
    { name: "我的", path: { link: "/pages/tabbar/mine/mine", app_link: { type: "mine" }.to_json }},
    { name: "账号管理", path: { link: "", app_link: { type: "member" }.to_json }},
    { name: "购物车", path: { link: "/pages/tabbar/shopping-cart/shopping-cart", app_link: { type: "shoppingCart" }.to_json }},
    { name: "全部商品列表", path: { link: "/pages/products/search/search", app_link: { type: "productSearch" }.to_json }},
    { name: "分类列表", path: { link: "/pages/tabbar/category/category", app_link: { type: "category" }.to_json }},
    { name: "点评/建议", path: { link: "/pages/feedback/feedback", app_link: { type: "page_feedback" }.to_json }},
    { name: "品牌馆", path: { link: "", app_link: { type: "brands" }.to_json }},
    { name: "签到活动", path: { link: "", app_link: { type: "signInActivity" }.to_json }},
    { name: "留学生认证", path: { link: "", app_link: { type: "overseasStudentApplication" }.to_json }},
    { name: "拍卖列表", path: { link: "", app_link: { type: "auctionList" }.to_json }},
    # { name: "当日达首页", path: { link: "", app_link: { type: "sameDayDeliveryHome" }.to_json }},
    { name: "跨境购首页", path: { link: "", app_link: { type: "aeDropShipperHome" }.to_json }},
    { name: "表格产品列表", path: { link: "", app_link: { type: "formItemList" }.to_json }},
    { name: "地区运费查询页", path: { link: "", app_link: { type: "deliveryAreas" }.to_json }},
    { name: "会员注册", path: { link: "/pages/vip/sign-in/sign-in", app_link: { type: "sign_in" }.to_json }},
    { name: "会员邀请", path: { link: "", app_link: { type: "invite" }.to_json }},
  ]

  class_methods do
    def grouped_links(store_id = nil, keyword = "")
      result = Hash.new { |hash, key| hash[key] = {} }

      result["固定页面"] = FIXED_PAGES

      MagicBean::Store.all.each do |store|
        result["门店"][store.name] = { link: "", app_link: "#{store.app_path}", name: store.name }
      end

      MagicBean::Category.top.includes(:translations).ransack(translations_name_cont: keyword, ae_drop_shipper_eq: false).result.find_each do |category|
        result["一级分类"][category.name] = { link: "/#{category.mini_program_path}", app_link: "#{category.app_path}", name: category.name }
      end

      MagicBean::Category.children.includes(:translations).ransack(translations_name_cont: keyword, ae_drop_shipper_eq: false).result.find_each do |category|
        result["二级分类"][category.name] = { link: "/#{category.mini_program_path}", app_link: "#{category.app_path}", name: category.name }
      end

      MagicBean::Category.top.includes(:translations).ransack(translations_name_cont: keyword, ae_drop_shipper_eq: true).result.find_each do |category|
        result["跨境购一级分类"][category.name] = { link: "/#{category.mini_program_path}", app_link: "#{category.app_path}", name: category.name }
      end

      MagicBean::Category.children.includes(:translations).ransack(translations_name_cont: keyword, ae_drop_shipper_eq: true).result.find_each do |category|
        result["跨境购二级分类"][category.name] = { link: "/#{category.mini_program_path}", app_link: "#{category.app_path}", name: category.name }
      end

      MagicBean::CouponPackage.active.ransack({ store_id_eq: store_id, name_cont: keyword }).result.find_each do |package|
        result["优惠券礼包"][package.name] = { link: "/#{package.mini_program_path}", app_link: "#{package.app_path}", name: package.name }
      end

      MagicBean::CouponTemplate.includes(:translations).active.ransack({ store_id_eq: store_id, translations_title_cont: keyword }).result.find_each do |template|
        result["优惠券"][template.title] = { link: "/#{template.mini_program_path}", app_link: "#{template.app_path}", name: template.title }
      end

      MagicBean::Item.includes(:translations).on_sale.ransack({ store_id_eq: store_id, translations_title_cont: keyword }).result.find_each do |item|
        result["单个产品"][item.title] = { link: "/#{item.mini_program_path}", app_link: "#{item.app_path}", name: item.title }
      end

      MagicBean::CustomPage.ransack({ store_id_eq: store_id, name_cont: keyword }).result.each do |custom_page|
        result["自定义页面"][custom_page.name] = { link: "/#{custom_page.mini_program_path}", app_link: "#{custom_page.app_path}", name: custom_page.name }
      end

      MagicBean::CustomList.includes(:translations).ransack({ store_id_eq: store_id, translations_title_cont: keyword }).result.each do |custom_list|
        result["自定义列表"][custom_list.title] = { link: "/#{custom_list.mini_program_path}", app_link: "#{custom_list.app_path}", name: custom_list.same_day_delivery_title }
      end

      MagicBean::Page.ransack(name_cont: keyword).result.find_each do |page|
        result["独立页面"][page.name] = { link: "/#{page.mini_program_path}", app_link: "#{page.app_path}", name: page.name }
      end

      MagicBean::EventPage.ransack(name_cont: keyword).result.find_each do |page|
        result["活动页面"][page.name] = { link: "/#{page.mini_program_path}", app_link: "#{page.app_path}", name: page.name }
      end

      MagicBean::Brand.includes(:translations).ransack(translations_name_cont: keyword).result.find_each do |brand|
        result["品牌"][brand.name] = { link: "/#{brand.mini_program_path}", app_link: "#{brand.app_path}", name: brand.name }
      end

      MagicBean::ExternalLink.ransack(name_cont: keyword).result.find_each do |external_link|
        result["外链"][external_link.name] = { link: "/#{external_link.mini_program_path}", app_link: "#{external_link.app_path}", name: external_link.name }
      end

      MagicBean::ExternalMiniProgram.ransack(name_cont: keyword).result.find_each do |external_mp|
        result["外部小程序"][external_mp.name] = { link: "#{external_mp.mini_program_path}", app_link: "#{external_mp.app_path}", name: external_mp.name }
      end

      MagicBean::LiveRoom.ransack(name_cont: keyword).result.find_each do |room|
        result["直播间"][room.title] = { link: "", app_link: "#{room.app_path}", name: room.title }
      end

      result
    end

    def links
      grouped_links.values.map(&:invert).inject(:merge)
    end
  end

  def link_name(link)
    self.class.links.dig(link)
  end
end
