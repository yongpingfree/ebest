$(document).on("turbolinks:load", function(){
  if (document.getElementById('download_page')) {
    function isWeiXin(){
      var ua = window.navigator.userAgent.toLowerCase();
      if(ua.match(/MicroMessenger/i) == 'micromessenger'){
        return true;
      }else{
        return false;
      }
    }

    /**
    * Determine the mobile operating system.
    * This function returns one of 'iOS', 'Android', 'Windows Phone', or 'unknown'.
    *
    * @returns {String}
    */

    function getMobileOperatingSystem() {
      var userAgent = navigator.userAgent || navigator.vendor || window.opera;

          // Windows Phone must come first because its UA also contains "Android"
        if (/windows phone/i.test(userAgent)) {
            return "Windows Phone";
        }

        if (/android/i.test(userAgent)) {
            return "Android";
        }

        // iOS detection from: http://stackoverflow.com/a/9039885/177710
        if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
            return "iOS";
        }

        return "unknown";
    }

    (function() {
      var system = getMobileOperatingSystem()
      /**
        * 需要配置以下选项
        * ANDROID_APP_DOWNLOAD_URL=''
        * IOS_APP_DOWNLOAD_URL=''
        */

      function replaceQrcodeWithButton(link) {
        var wxPopup = document.getElementById('JweixinTip')
        button = document.createElement('a')
        button.id = 'download_btn'
        button.textContent = '点击下载'
        button.target = '_blank'
        button.href = link
        var imageArea = document.getElementById('image_area')
        imageArea.replaceWith(button)
        wxPopup.addEventListener('click', function(e) {
          e.preventDefault()
          wxPopup.style.display = 'none'
        })

        button.addEventListener('click', function(e) {
          if (isWeiXin()) {
            e.preventDefault()
            wxPopup.style.display = 'block'
          }
        })
      }

      if (system === 'iOS') {
        var iosLink = "https://apps.apple.com/cn/app/ebest/id1462561698"
        replaceQrcodeWithButton(iosLink)
        window.location.href = iosLink
      } else if (system === 'Android') {
        var androidLink = "https://play.google.com/store/apps/details?id=com.donkibuy.ebest"
        replaceQrcodeWithButton(androidLink)
        if (!isWeiXin()) {
          window.location.href = androidLink
        }
      }
    })()
  }
});
