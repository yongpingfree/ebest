const { environment } = require('@rails/webpacker')

environment.config.merge({
  resolve: {
    alias: {
      'vue$': 'vue/dist/vue.esm.js'
    }
  }
})

module.exports = environment
