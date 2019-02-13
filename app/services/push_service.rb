class PushService
  def send_update_store(channel, app_name, data)
    channel = Channel.add_app_name_suffix(channel, app_name)
    SocketioSendJob.perform_later(channel, "update_store", data.to_json, true)
  end

  def send_notification(channel, app_name, data)
    data[:message] = ActionView::Base.full_sanitizer.sanitize(data[:message])
    data[:date] = Time.now.to_json.tr('"','')
    channel = Channel.add_app_name_suffix(channel, app_name)
    SocketioSendJob.perform_later(channel, "notification", data.to_json)
    AzureNotifyJob.perform_later(channel, data, app_name)
  end
end
