
#' A phylosql Function
#'
#'
#' @param si_long data to upload
#' @keywords
#' @import dplyr
#' @import RMariaDB
#' @export
#'

create_sampleInfo_table<- function(si_long, ... ){

  vars<- unique(si_long$variable)
  samples<- unique(si_long$MetagenNumber)
  rows<- length(samples)
  cols<- length(vars)
  sample_data<- matrix(NA,ncol=cols, nrow=rows)

  sampleList<- split(si_long,si_long$MetagenNumber)

  for(i in seq_along(sampleList)){
    sample_data[i,match(sampleList[[i]]$variable, vars)  ]<- sampleList[[i]]$value
  }

  rownames(sample_data)<- samples
  colnames(sample_data)<- vars
  sample_data<- data.frame(sample_data)
  sample_data$MetagenNumber<- samples

  return(sample_data)
}

#' A phylosql Function
#'
#'
#' @param flist
#' @param con connection
#' @keywords
#' @import dplyr
#' @import RMariaDB
#' @export
#'

fetch_sampleInfo<-
  function(flist=NULL, con=NULL){
    if(is.null(con)){
      stop("You need to specify a database connection")
    }

    si<- as_tibble(tbl(con,"labdata"))
    sample_info<- create_sampleInfo_table(si_long=si)
    cms<- as_tibble(tbl(con,"cmsdata"))
    sampleInfo <- merge(sample_info,cms,"MetagenNumber")

    if(!is.null(flist)){
      sampleInfo<- subset(sampleInfo,flist)
    }

    class(sampleInfo)<- c(class(sampleInfo), "sampledata")

    return(sampleInfo)

  }


#' A phylosql Function
#'
#'
#' @param phylo logical
#' @param database database to send data
#' @param con connection
#' @param whichSamples select specific samples to access
#' @keywords
#' @import dplyr
#' @import RMariaDB
#' @export
#'

fetch_asv_table<- function(con=NULL,database="eukaryota_sv",phylo=FALSE, whichSamples=NULL ){

  if(is.null(con)){
    stop("You need to specify a database connection")
  }
  # fetch data
  asv_long<- dplyr::as_tibble(dplyr::tbl(con,database))

  if(!is.null(whichSamples)){
    asv_long<- asv_long %>%
      filter(!!asv_long$MetagenNumber %in% whichSamples )
  }

  # Construct table
  asvs<- unique(asv_long$SV)
  samples<- unique(asv_long$MetagenNumber)
  rows<- length(samples)
  cols<- length(asvs)
  asv_table<- matrix(0L,ncol=cols, nrow=rows)

  sampleList<- split(asv_long,asv_long$MetagenNumber)

  for(i in seq_along(sampleList)){
    asv_table[i,match(sampleList[[i]]$SV, asvs)  ]<- sampleList[[i]]$Abundance
  }

  rownames(asv_table)<- samples
  colnames(asv_table)<- asvs

  # Set class (or not)
  if(phylo==FALSE){
  class(asv_table)<- "abundance"
  }

  return(asv_table)

}

#' A phylosql Function
#'
#' @param phylo logical. Whether to format data for phyloseq or sparseHDD.
#' @param database database to send data
#' @param con connection
#' @param whichTaxa select specific taxa
#' @keywords
#' @import dplyr
#' @import RMariaDB
#' @export
#'


fetch_taxonomy<- function(con=NULL, database="eukaryota_tax",whichTaxa=NULL, phylo=FALSE){

  if(is.null(con)){
    stop("You need to specify a database connection")
  }

  tax<- dplyr::as_tibble(dplyr::tbl(con,"eukaryota_tax"))

  if(!is.null(whichTaxa)){
    tax<- tax %>%
      filter(!!tax$SV %in% whichSamples )
  }


  if(phylo==FALSE){

    class(tax)<- c( "taxonomy",class(tax))

  }else{
    SV<- tax$SV
    tax<- tax[,-1]
    tax<- as.matrix(tax)
    rownames(tax)<- SV
  }
   return(tax)

}

