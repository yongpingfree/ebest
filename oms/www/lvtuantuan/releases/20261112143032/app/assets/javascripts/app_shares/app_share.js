$(document).on("turbolinks:load", function(){
  if (document.getElementById('app_share_page')) {
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

      function weiXinBrowserAction(link) {
        var wxPopup = document.getElementById('JweixinTip')
        button = document.createElement('a')
        button.id = 'download_btn'
        button.textContent = '点击下载'
        button.target = '_blank'
        button.href = link
        var imageArea = document.getElementById('image_area')
        imageArea.append(button)

        if (isWeiXin()) {
          wxPopup.style.display = 'block'
        }
      }
      if (system === 'iOS') {
        var iosLink = "https://apps.apple.com/cn/app/ebest/id1462561698"
        weiXinBrowserAction(iosLink)
      } else if (system === 'Android') {
        var androidLink = "https://play.google.com/store/apps/details?id=com.donkibuy.ebest"
        weiXinBrowserAction(androidLink)
      }
    })()
  }
});
