# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadRemoteXlsxConcern do
  let(:model_class) do
    Class.new do
      include LoadRemoteXlsxConcern
    end
  end

  it "白名单外地址拒绝且不发起网络请求" do
    expect(Roo::Spreadsheet).not_to receive(:open)
    result, message = model_class.try_load_remote_file("https://evil.com/a.xlsx")
    expect(result).to be_nil
    expect(message).to eq("文件地址不受支持，请通过后台上传后导入")
  end

  it "file:// 路径拒绝" do
    result, message = model_class.try_load_remote_file("file:///etc/passwd.xlsx")
    expect(result).to be_nil
    expect(message).to eq("文件地址不受支持，请通过后台上传后导入")
  end

  it "内网地址拒绝" do
    result, message = model_class.try_load_remote_file("http://169.254.169.254/latest/meta-data/a.xlsx")
    expect(result).to be_nil
    expect(message).to eq("文件地址不受支持，请通过后台上传后导入")
  end

  it "白名单内 S3 直连域通过并加载 xlsx" do
    xlsx_double = double("xlsx")
    allow(Roo::Spreadsheet).to receive(:open)
      .with("https://ebest-production.s3.ap-southeast-2.amazonaws.com/import/a.xlsx", extension: :xlsx)
      .and_return(xlsx_double)

    result, message = model_class.try_load_remote_file("https://ebest-production.s3.ap-southeast-2.amazonaws.com/import/a.xlsx")
    expect(result).to eq(xlsx_double)
    expect(message).to be_nil
  end

  it "白名单内非 xlsx 扩展名仍报格式不支持" do
    expect(Roo::Spreadsheet).not_to receive(:open)
    result, message = model_class.try_load_remote_file("https://cdn.minimall.donkibuy.com/import/a.csv")
    expect(result).to be_nil
    expect(message).to eq("不支持的文件格式，请上传 xlsx 格式文件")
  end
end
