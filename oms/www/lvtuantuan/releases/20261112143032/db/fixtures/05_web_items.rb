# frozen_string_literal: true

MagicBean::WebItem.seed_once(
  :id,
  {
    id: 1,
    item_id: 1,
    video: "http://devcdn.beansmile-dev.com/liU5829KVTfLN1RtVU7XdlJgQ8xK",
    upper_images: ["https://picsum.photos/1024/480/?image=52", "https://picsum.photos/1024/480/?image=58"],
    lower_images: ["https://picsum.photos/1024/480/?image=58", "https://picsum.photos/1024/480/?image=55"],
    banner_images: ["https://picsum.photos/1024/480/?image=52", "https://picsum.photos/1024/480/?image=58", "https://picsum.photos/1024/480/?image=55"],
  },
  {
    id: 2,
    item_id: 2,
    video: "http://devcdn.beansmile-dev.com/liU5829KVTfLN1RtVU7XdlJgQ8xK",
    upper_images: ["https://picsum.photos/1024/480/?image=52", "https://picsum.photos/1024/480/?image=58"],
    lower_images: ["https://picsum.photos/1024/480/?image=58", "https://picsum.photos/1024/480/?image=55"],
    banner_images: ["https://picsum.photos/1024/480/?image=52", "https://picsum.photos/1024/480/?image=58", "https://picsum.photos/1024/480/?image=55"],
  }
)
