suppressMessages(library(tidyverse))
suppressMessages(library(rvest))
suppressMessages(library(parallel))

set.seed(1)
files <- dir('./data/',full.names=TRUE)
#files <- files[sample(1:length(files),size=1e4)]

cores <- detectCores()

#returns the xml data without the header
get_xscript <- function(x){
	x %>%
		read_file %>%
		read_xml %>%
		xml_children %>%
		.[2]
}

talkers <- mclapply(mc.cores = cores,files,function(x){tryCatch({get_xscript(x) %>%
	       xml_find_all('//name') %>%
	       xml_text},error=function(e)NA_character_)}
       )

speeches <- mclapply(mc.cores = cores,files,function(x){
			     tryCatch({speeches <- x %>%
				     get_xscript %>%
				     xml_find_all('//body') %>%
				     xml_children
			     map(speeches,xml_text) %>%
				     keep(~.x!='')
	       },error=function(e)NA_character_)
       }
)

names(speeches) <- files

speeches <- speeches[map_lgl(talkers,~length(.x)>0)]

parliamentarian_name_regex <- '^(Reverend the Hon.|Mr|Ms|Mrs|The Hon.|The Hon. Dr|Dr|The) [A-Za-z\\.]+.*:'

process_fragment <- function(x){
	topic <- x[[1]]
	x[[1]] <- NULL
	statements <- list()
	i <- 1
	current_speaker <- NA
	for (paragraph in x){
		paragraph <- str_trim(paragraph) # some start with multiple whitespaces
		speaker <- str_extract(paragraph,parliamentarian_name_regex)
		if (is.na(speaker)){
			speaker <- current_speaker
			if (length(statements)==i){
			statements[[i]] <- paste(statements[[i]],paragraph,sep=rep('\n',100))
			} else {
			statements[[i]] <- paragraph
			names(statements)[i] <- speaker
			}
		} else {
			i <- i+1
			statements[[i]] <- paragraph
			names(statements)[i] <- speaker
		}
		current_speaker <- speaker
	}
	statements <- keep(statements,~!is.null(.x))
	tibble(topic = rep(topic,length(statements)),speaker=names(statements),statement=unlist(statements))
}

speeches <- mclapply(mc.cores=cores,speeches,process_fragment) %>%
	bind_rows %>%
	feather::write_feather('speeches.feather')
