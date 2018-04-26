suppressMessages(library(tidyverse))
library(rvest)
library(tidytext)

files <- dir('data',full.names=TRUE)

map(files,~ read_file(.x) %>%
    read_html %>%
    html_text %>%
    tibble(speech=.)
) %>% bind_rows() %>%
	mutate(speech_id = row_number()) %>%
	unnest_tokens(word,speech) %>%
	anti_join(stop_words) %>%
	count(speech_id,word) %>%
	filter(grepl(word,pattern='^[a-z]+$')) -> speeches

hansard_dtm <- speeches %>%
	cast_dtm(speech_id,word,n)
