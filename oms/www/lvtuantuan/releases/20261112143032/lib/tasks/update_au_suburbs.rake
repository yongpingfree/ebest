# frozen_string_literal: true

namespace :hotfix do
  desc "update au suburbs"
  task update_au_suburbs: :environment do
    MagicBean::AuSuburb.destroy_all
    xlsx = Roo::Spreadsheet.open("./db/data/au-towns.xlsx")
    sheet = xlsx.sheet(0)
    (2..sheet.last_row).each do |index|
      row = sheet.row(index)

      MagicBean::AuSuburb.find_or_create_by!(
        name: row[1],
        state_short_name: row[2],
        state_name: row[3],
        postal_code: row[4],
        latitude: row[5],
        longitude: row[6]
      )
    end

    MagicBean::DeliveryArea.find_each do |da|
      next if da.au_suburb.present?
      suburb = MagicBean::AuSuburb.find_by(
        name: da.suburb,
        postal_code: da.postal_code
      )

      da.update!(au_suburb_id: suburb.id) if suburb
    end
  end

  # 数据由小sam提供，只拿表格中id为空的记录做创建操作
  desc "update au suburbs 2020"
  task update_au_suburbs_2020: :environment do
    xlsx = Roo::Spreadsheet.open("./db/data/au-postcode-2020.xlsx")
    sheet = xlsx.sheet(0)
    (2..sheet.last_row).each do |index|
      row = sheet.row(index)
      if row[0].blank?
        suburb = MagicBean::AuSuburb.find_or_create_by!(
          name: row[1],
          postal_code: row[4]
        )

        suburb.update_columns(
          state_name: row[2],
          state_short_name: row[3],
          latitude: row[5],
          longitude: row[6],
          store_id: row[7]
        )
      end
    end
  end
end
