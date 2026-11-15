# frozen_string_literal: true

class AddCodeToProvincesAndCitiesAndCounties < ActiveRecord::Migration[5.2]
  def change
    add_column :provinces, :code, :string
    add_column :cities, :code, :string
    add_column :counties, :code, :string

    say_with_time "update code for regions" do
      MagicBean::Province.reset_column_information
      MagicBean::City.reset_column_information
      MagicBean::County.reset_column_information

      MagicBean::Province.find_each do |province|
        province.send :update_code

        province.cities.find_each do |city|
          city.send :update_code

          city.counties.find_each do |county|
            county.send :update_code
          end
        end
      end
    end
  end
end
