#Script to download transcripts from the NSW Hansard.
#Uses API documented at http://parliament-api-docs.readthedocs.io/en/latest/new-south-wales/#get-hansard-by-year



library(purrr)
library(readr)
library(stringr)
library(progress)
suppressMessages(library(jsonlite))
suppressMessages(library(lubridate))



begin <- ymd('2010-01-01')

end <- ymd('2010-06-01')

days <- seq(begin,end,1) %>%
	as.character()

pb <- progress_bar$new(
		       format = "getting document ids [:bar] :percent in :elapsed",
		       total = length(days), clear=FALSE,width=60
		       )


days <- map(days, function(x) {
		    res <- paste0('https://api.parliament.nsw.gov.au/api/hansard/search/bydate?date=',x) %>%
			    url %>%
			    read_file()
		    pb$tick()
		    res
		       }
)

#days <- map(days,~paste0('https://api.parliament.nsw.gov.au/api/hansard/search/bydate?date=',.x) %>%
#	     url %>%
#	     read_file()
 #    ) %>%
#	keep(~.x != "{\"data\":[]}") 

document_descriptions <- days %>%
  map(~fromJSON(.x,simplifyDataFrame = FALSE)) %>%
  map(~.x[['data']]) %>%
  map(~map(.x,'Details')) %>%
  purrr::flatten() %>%
  purrr::flatten()



document_ids <- map_chr(document_descriptions,'DocumentId')
names(document_ids) <- map_chr(document_descriptions,'Text')

already_seen <- dir('./data') %>%
	str_split(pattern='\\.') %>%
	map_chr(~.x[[1]])

document_ids <- document_ids[!(document_ids %in% already_seen)]

transcript_url <- function(docID){
    paste0('https://api.parliament.nsw.gov.au/api/hansard/search/daily/fragment/',docID)
}

pb <- progress_bar$new(
		       format = "downloading documents [:bar] :percent in :elapsed",
		       total = length(document_ids),clear=FALSE,width=60
		       )

docs <- map(document_ids,function(x){
		    res <- try(transcript_url(x) %>%
			url %>%
			read_file()
		)
		    pb$tick()
		    res
}
)

#docs <- map(document_ids,~try(transcript_url(.x) %>%
#    url %>%
#    read_file()
#    ) 
#)

docs <- set_names(docs,document_ids)

docs <- keep(docs,~class(.x)!='try-error')

map2(docs,names(docs),~write_file(.x,path=paste0('./data/',.y,'.xml')))

