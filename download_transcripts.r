#Script to download transcripts from the NSW Hansard.
#Uses API documented at http://parliament-api-docs.readthedocs.io/en/latest/new-south-wales/#get-hansard-by-year

library(purrr)
library(readr)
library(jsonlite)
library(lubridate)



begin <- ymd('2005-01-01')

end <- ymd('2005-04-01')

days <- seq(begin,end,1) %>%
	as.character()

days <- map(days,~paste0('https://api.parliament.nsw.gov.au/api/hansard/search/bydate?date=',.x) %>%
	     url %>%
	     read_file()
     ) %>%
	keep(~.x != "{\"data\":[]}") 

document_ids <-map(days,~fromJSON(.x,simplifyDataFrame=FALSE)) %>%
	rapply(f=I) %>% .[grep(.,pattern='HANSARD')]

transcript_url <- function(docID){
    paste0('https://api.parliament.nsw.gov.au/api/hansard/search/daily/fragment/',docID)
}


docs <- map(document_ids,~try(transcript_url(.x) %>%
    read_file())
) 
