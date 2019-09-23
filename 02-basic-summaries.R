source("01-users-and-location-extraction.R")

# location summary ----

# notice that many users have NA location and that there are users with
# multiple locations

location_summary <- followers_info_w_location %>% 
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

drop_na(location_summary) %>% 
  filter(row_number() <= 10) %>% 
  mutate(location = as_factor(location)) %>% 
  ggplot() +
  geom_col(aes(x = location, y = n_users)) +
  coord_flip() +
  theme_minimal() +
  labs(title = "Top 10 locations of @ropensci followers)

# mentions summary ----

twitter_metrics <- read_csv("../ropensci-tweets/twitter_metrics_monthly_rOpenSci.csv")

twitter_metrics %>% 
  filter(year(date) == 2019) %>% 
  mutate(week = week(date)) %>% 
  group_by(week) %>% 
  summarise(mentions = sum(mentions, na.rm = T)) %>% 
  ggplot() +
  geom_line(aes(x = week, y = mentions)) +
  theme_minimal() +
  labs(title = "Mentions during 2019's weeks")
