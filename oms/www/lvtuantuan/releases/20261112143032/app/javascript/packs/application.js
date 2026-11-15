import Vue from 'vue'
import Loading from 'element-ui/lib/loading'
import Dialog from 'element-ui/lib/dialog'
import Drawer from 'element-ui/lib/drawer'
import Carousel from 'element-ui/lib/carousel'
import CarouselItem from 'element-ui/lib/carousel-item'
import lineClamp from 'vue-line-clamp'
import 'normalize.css'
import 'github-markdown-css'
import '../script/video-view'
import '../script/list-page'

const elFiles = require.context('element-ui/lib/theme-chalk', true, /(row|col|icon|input|loading|dialog|carousel|carousel-item|drawer|display)\.css$/)

if (process.env.NODE_ENV === 'development') {
  require.context('raw-loader!../../views', true) // 开发环境下监听 erb 文件
  elFiles.keys().forEach(elFiles)
}

require('../style/application.scss')

Vue.use(lineClamp).use(Loading).use(Carousel).use(CarouselItem).use(Dialog).use(Drawer)

Vue.component('home-index', {
  data() {
    return { active: 1 }
  }
})

new Vue({
  el: '#app',
  data: {
    home_carousel_active: 1,
    header_drawer: false,
    qrcode: '',
    qrcode_title: '',
    show_qrcode: false,
  },
  methods: {
    showQRCode(qrcode, title) {
      this.qrcode = qrcode
      this.qrcode_title = title
      this.show_qrcode = true
    }
  }
})
