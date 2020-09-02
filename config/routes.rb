Rails.application.routes.draw do

  get '/' => 'game#game'

  get 'login' => 'login#login'
  post 'try_login' => 'login#try_login'

  get 'invite/:code' => 'invite#invited'
  post 'redeem_invite' => 'invite#redeem_invite'

  post 'save_formation' => 'api#save_formation'
  get 'load_world' => 'api#load_world'
  get 'history/:season' => 'api#history'
  get 'squad/:id' => 'api#view_team'
  get 'game_events/:id' => 'api#game_events'
  get 'game_events_since/:id/:event_id' => 'api#game_events_since'
  get 'game_events_since/:id/' => 'api#game_events_since'
  get 'tables' => 'api#league_tables'
  get 'fixtures' => 'api#fixtures'
  get 'transfer_listings' => 'api#transfer_listings'
  get 'news_articles' => 'api#news_articles'
  get 'top_scorers' => 'api#top_scorers'
  post 'transfer_bid' => 'api#transfer_bid'
  post 'sell_player' => 'api#sell_player'
  post 'delete_message' => 'api#delete_message'
  post 'got_fcm_token' => 'api#got_fcm_token'

  # routes with modified METHOD for TS port
  post 'squad' => 'api#view_team'
  post 'load_world' => 'api#load_world'
  post 'tables' => 'api#league_tables'
  post 'fixtures' => 'api#fixtures'
  post 'get_game' => 'api#game_events'
  post 'game_events_since' => 'api#game_events_since'
  post 'news_articles' => 'api#news_articles'
  post 'history' => 'api#history'
  post 'transfer_listings' => 'api#transfer_listings'
  post 'top_scorers' => 'api#top_scorers'
  post 'finances' => 'api#finances'
end
