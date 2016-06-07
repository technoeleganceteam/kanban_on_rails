if Cookies.get('signed_in') and Cookies.get('signed_in') == '1'
  App.user_notifications = App.cable.subscriptions.create 'UserNotificationsChannel',
    connected: ->
      # Called when the subscription has been created
   
    disconnected: ->
      # Called when the subscription has been terminated by the server
   
    received: (data) ->
      switch data.type
        when 'notification'
          @_handle_notification(data)
        when 'stop_sync_notification'
          @_handle_notification(data)

          $("#navbar_#{ data.provider }_sync_info").remove() if data.provider


    _handle_notification: (data) ->
      if !('Notification' of window)
        @_show_noty(data)
      else if Notification.permission == 'granted'
        @_show_notification(data)
      else if Notification.permission != 'denied'
        Notification.requestPermission (permission) =>
          if permission == 'granted' then @_show_notification(data) else @_show_noty(data)
      else
        @_show_noty(data)

    _show_noty: (data) ->
      noty
        text: "#{ data.title_with_body_html }"
        type: 'information'
        theme: 'bootstrapTheme'
        dismissQueue: true
        layout: 'topRight'
        buttons: false
        timeout: 2000
        maxVisible: 1

    _show_notification: (data) ->
      n = new Notification data.title,
        tag: data.title
        body: data.body
        icon: $('#desktop_icon').text().trim()

      setTimeout(n.close.bind(n), 2000)
