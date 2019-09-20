source("01-data-extraction.R")

# example summaries ----

# notice that many users have NA location and that there are users with
# multiple locations

followers_info_w_location %>% 
  group_by(lon, lat) %>% 
  summarise(n_users = n()) %>% 
  ungroup() %>% 
  left_join(
    coded %>% 
      drop_na() %>% 
      distinct(lon, lat, .keep_all = T)
  ) %>% 
  mutate(date = Sys.Date()) %>% 
  select(date, location, n_users) %>% 
  arrange(-n_users)
