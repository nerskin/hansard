#Script to download transcripts from the NSW Hansard.
#Uses API documented at http://parliament-api-docs.readthedocs.io/en/latest/new-south-wales/#get-hansard-by-year

library(purrr)
library(readr)
suppressMessages(library(jsonlite))
suppressMessages(library(lubridate))



begin <- ymd('2010-02-01')

end <- ymd('2010-05-01')

days <- seq(begin,end,1) %>%
	as.character()

days <- map(days,~paste0('https://api.parliament.nsw.gov.au/api/hansard/search/bydate?date=',.x) %>%
	     url %>%
	     read_file()
     ) %>%
	keep(~.x != "{\"data\":[]}") 

document_descriptions <- days %>%
  map(~fromJSON(.x,simplifyDataFrame = FALSE)) %>%
  map(~.x[['data']]) %>%
  map(~map(.x,'Details')) %>%
  purrr::flatten() %>%
  purrr::flatten()



document_ids <- map_chr(document_descriptions,'DocumentId')
set_names(document_ids,map_chr(document_descriptions,'Text'))

document_descriptions

#document_ids <- map(days,~fromJSON(.x,simplifyDataFrame=FALSE)) %>%
#	rapply(f=I) %>% .[grep(.,pattern='HANSARD')]

#document_ids <- document_ids[names(document_ids) != 'data.PdfDocumentId']

transcript_url <- function(docID){
    paste0('https://api.parliament.nsw.gov.au/api/hansard/search/daily/fragment/',docID)
}

docs <- map(document_ids,~try(transcript_url(.x) %>%
    read_file())
)

docs <- set_names(docs,document_ids)

docs <- keep(docs,~class(.x)!='try-error')

map2(docs,names(docs),~write_file(.x,path=paste0(.y,'.xml')))

