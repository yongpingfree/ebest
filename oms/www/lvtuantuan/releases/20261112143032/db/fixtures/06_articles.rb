# frozen_string_literal: true

if MagicBean::Page.article.empty?
  MagicBean::Page.article.create!(
    {
      name: "EVENT 2019",
      content: "<video src=\"http://devcdn.beansmile-dev.com/liU5829KVTfLN1RtVU7XdlJgQ8xK\"/>",
      cover: "https://picsum.photos/1024/480/?image=52",
      desc: "eBest, Chinese word for it is “SHI, LE ” (Stone, Pleasure).",
    }
  )

  MagicBean::Page.article.create!(
    {
      name: "EVENT 20120",
      content: "<video src=\"http://devcdn.beansmile-dev.com/liU5829KVTfLN1RtVU7XdlJgQ8xK\"/>",
      cover: "https://picsum.photos/1024/480/?image=58",
      desc: "eBest was born on the basis of physical attention,\nand all",
    }
  )
end
