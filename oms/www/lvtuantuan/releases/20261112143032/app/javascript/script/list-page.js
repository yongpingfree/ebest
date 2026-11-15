import Vue from 'vue'

const List = Vue.extend({
  props: ['total', 'list', 'keyword'],
  data() {
    return { loading: false, data: this.list }
  },
  computed: {
    finished() {
      return this.data.length >= this.total
    }
  },
  methods: {
    async fetchMore() {
      this.loading = true
      try {
        const res = await fetch(`${location.pathname}.json?offset=${this.data.length}&keyword=${this.keyword}`)
        if (res.status >= 200 && res.status < 300) {
          const data = await res.json()
          this.data.push(...data)
        }
      } finally {
        this.loading = false
      }
    }
  }
})

Vue.component('products-index', List)
Vue.component('articles-index', List)
