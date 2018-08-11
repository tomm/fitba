# Be sure to restart your server when you modify this file.

# expire after 1 day so that app reload is forced, and people get new features ;)
Rails.application.config.session_store :cookie_store, key: '_fitba_server_session', expire_after: 1.days
