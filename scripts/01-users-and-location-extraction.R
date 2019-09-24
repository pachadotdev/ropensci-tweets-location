# packages ----

if (!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse, rtweet, ggmap, sp, rworldmap, rworldxtra, countrycode, lubridate)

# files ----

try(dir.create("data"))

followers_rda <- sprintf("data/followers-%s.rda", Sys.Date())

followers_info_rda <- sprintf("data/followers-info-%s.rda", Sys.Date())

coded_rda <- sprintf("data/coded-%s.rda", Sys.Date())

followers_country_rda <- sprintf("data/followers-country-%s.rda", Sys.Date())

# friends and followers ----

if (!file.exists(followers_rda)) {
  followers <- rtweet::get_followers("ropensci", n = 50000, retryonratelimit = T)
  save(followers, file = followers_rda, compress = "xz")
} else {
  load(followers_rda)
}

# friends and followers details ----

if (!file.exists(friends_info_rda)) {
  followers_info <- lookup_users(followers$user_id)
  save(followers_info, file = followers_info_rda, compress = "xz")
} else {
  load(followers_info_rda)
}

# locations ----

# go to https://cloud.google.com/maps-platform/
# I already registered a maps account with an API key stored in .Rprofile
# that key shall use geolocation and geocoding APIs

if (!file.exists(coded_rda)) {
  register_google(gmaps_token_api_key)
  
  coded <- discard(followers_info$location, `==`, "") %>% 
    unique() %>% 
    geocode()
  
  coded$location <- discard(friends_info$location, `==`, "") %>% unique()
  
  save(coded, file = coded_rda, compress = "xz")
} else {
  load(coded_rda)
}

# locations 2 ----

# with the location converted to coordinates, now I get the country

# coords2country was taken from
# https://stackoverflow.com/questions/14334970/convert-latitude-and-longitude-coordinates-to-country-name-in-r

coords2country <- function(points) {  
  countriesSP <- getMap(resolution = 'high')

  # setting CRS directly to that from rworldmap
  pointsSP <- SpatialPoints(points, proj4string = CRS(proj4string(countriesSP)))  
  
  # use 'over' to get indices of the Polygons object containing each point 
  indices <- over(pointsSP, countriesSP)
  
  # return the ADMIN names of each country
  indices$ADMIN  
}

coded <- drop_na(coded)

coded <- coded %>% 
  mutate(
    country = coords2country(round(coded[,1:2],2)),
    country = as.character(country)
  ) %>% 
  drop_na()

# join users with locations ----

if (!file.exists(followers_country_rda)) {
  followers_info_w_location <- left_join(followers_info, coded, by = "location")
  
  followers_by_country <- followers_info_w_location %>% 
    mutate(country = ifelse(is.na(country.y), "Undetermined location", country.y)) %>% 
    group_by(country) %>% 
    summarise(n_followers = n()) %>% 
    arrange(-n_followers)
  
  save(followers_by_country, file = followers_country_rda, compress = "xz")
} else {
  load(followers_country_rda)
}