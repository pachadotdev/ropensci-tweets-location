# packages ----

if (!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse, rtweet, ggmap)

# files ----

followers_rda <- sprintf("followers-%s.rda", Sys.Date())
friends_rda <- sprintf("friends-%s.rda", Sys.Date())

followers_info_rda <- sprintf("followers-info-%s.rda", Sys.Date())
friends_info_rda <- sprintf("friends-info-%s.rda", Sys.Date())

coded_rda <- sprintf("coded-%s.rda", Sys.Date())

# friends and followers ----

if (!file.exists(followers_rda)) {
  followers <- rtweet::get_followers("ropensci", n = 50000, retryonratelimit = T)
  save(followers, file = followers_rda, compress = "xz")
} else {
  load(followers_rda)
}

if (!file.exists(friends_rda)) {
  friends <- rtweet::get_friends("ropensci", n = 50000, retryonratelimit = T)
  save(friends, file = friends_rda, compress = "xz")
} else {
  load(friends_rda)
}

# friends and followers details ----

if (!file.exists(friends_info_rda)) {
  followers_info <- lookup_users(followers$user_id)
  save(followers_info, file = followers_info_rda, compress = "xz")
} else {
  load(followers_info_rda)
}

if (!file.exists(friends_info_rda)) {
  friends_info <- lookup_users(friends$user_id)
  save(friends_info, file = friends_info_rda, compress = "xz")
} else {
  load(friends_info_rda)
}

# locations ----

# go to https://cloud.google.com/maps-platform/
# I already registered a maps account with an API key stored in .Rprofile
# that key shall use geolocation and geocoding APIs

if (!file.exists(coded_rda)) {
  register_google(gmaps_token_api_key)
  
  coded_1 <- discard(friends_info$location, `==`, "") %>% 
    unique() %>% 
    geocode()
  
  coded_1$location <- discard(friends_info$location, `==`, "") %>% unique()
  
  coded_2 <- discard(followers_info$location, `==`, "") %>% unique()
  coded_2 <- coded_2[!coded_2 %in% coded_1$location]
  
  coded_2 <- coded_2 %>% geocode()
  
  coded_2_location <- discard(followers_info$location, `==`, "") %>% unique()
  coded_2_location <- coded_2_location[!coded_2_location %in% coded_1$location]
  
  coded_2$location <- coded_2_location
  
  coded <- coded_1 %>% 
    bind_rows(coded_2)
  
  save(coded, file = coded_rda, compress = "xz")
} else {
  load(coded_rda)
}

# join users with locations ----

followers_info_w_location <- left_join(followers_info, coded, by = "location")

friends_info_w_location <- left_join(friends_info, coded, by = "location")
