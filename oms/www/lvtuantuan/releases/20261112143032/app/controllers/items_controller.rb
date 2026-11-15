# frozen_string_literal: true

class ItemsController < ApplicationController
  def index
    collection = MagicBean::Item.on_sale.includes(:taggings).ransack(title_or_sub_title_or_description_cont_any: params[:keyword]).result.order(created_at: :desc)
    @items = collection.limit(params[:limit] || 6).offset(params[:offset])

    respond_to do |format|
      format.html do
        @total = collection.size
        @site_config = MagicBean::SiteConfig.default_config
      end
      format.json { render json: @items }
    end
  end

  def show
    @item = MagicBean::Item.on_sale.find(params[:id])
    @web_item = @item.web_item
  end
end
