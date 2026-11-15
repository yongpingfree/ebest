import Vue from 'vue'

Vue.component('video-view', {
  props: ['src', 'poster'],
  data() {
    return { paused: true, played: false }
  },
  methods: {
    watchVideo(e) {
      this.paused = e.target.paused
      this.played = true
    },
    onClick(e) {
      const { target } = e
      if (target.played.length === 0) target.play()
    },
    play() {
      this.$refs.video.play()
    }
  },
  template: '#video_view_template'
})
